"""Production training pipeline for SmartPlot Room-Relationship ML models.

Adheres strictly to ml-best-practices:
- Split dataset by original floor plan identity BEFORE fitting preprocessing.
- Fit ColumnTransformer exclusively on training split; transform validation and test splits independently.
- Benchmarks against Dummy majority-class and Logistic Regression baselines.
- Saves trained models, preprocessor, feature schema, and evaluation metrics.
"""
import json
import logging
import os
import sys
import time
from typing import Dict, List, Tuple

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.dummy import DummyClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from backend.app.ml.dataset import build_pairwise_dataframe, load_resplan_split

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("smartplot.ml.train")

ARTIFACTS_DIR = os.path.join(os.path.dirname(__file__), "artifacts")
DATA_DIR = os.path.join("data", "resplan")

NUMERICAL_COLS = [
    "plot_width",
    "plot_length",
    "plot_area",
    "plot_aspect_ratio",
    "total_rooms",
    "num_bedrooms",
    "num_bathrooms",
    "has_living",
    "has_kitchen",
    "has_parking",
    "is_same_category",
    "room1_area_ratio",
    "room2_area_ratio",
    "pair_area_ratio",
]

CATEGORICAL_COLS = [
    "room1_category",
    "room2_category",
    "pair_type",
]


def evaluate_model(
    model,
    X_test,
    y_test,
    model_name: str,
    target_name: str,
) -> Dict:
    """Computes comprehensive classification metrics on held-out test data."""
    preds = model.predict(X_test)
    probs = model.predict_proba(X_test)[:, 1] if hasattr(model, "predict_proba") else preds

    acc = float(accuracy_score(y_test, preds))
    prec = float(precision_score(y_test, preds, zero_division=0))
    rec = float(recall_score(y_test, preds, zero_division=0))
    f1 = float(f1_score(y_test, preds, zero_division=0))
    try:
        auc = float(roc_auc_score(y_test, probs))
    except Exception:
        auc = 0.5

    cm = confusion_matrix(y_test, preds).tolist()
    # tn, fp, fn, tp
    tn, fp, fn, tp = cm[0][0], cm[0][1], cm[1][0], cm[1][1]

    metrics = {
        "model": model_name,
        "target": target_name,
        "test_samples": len(y_test),
        "positive_samples": int(sum(y_test)),
        "negative_samples": int(len(y_test) - sum(y_test)),
        "class_imbalance_ratio": round(float(sum(y_test)) / len(y_test), 4),
        "accuracy": round(acc, 4),
        "precision": round(prec, 4),
        "recall": round(rec, 4),
        "f1_score": round(f1, 4),
        "roc_auc": round(auc, 4),
        "confusion_matrix": {
            "true_negatives": int(tn),
            "false_positives": int(fp),
            "false_negatives": int(fn),
            "true_positives": int(tp),
        },
    }

    logger.info(
        f"[{model_name} | {target_name}] Acc: {acc:.4f} | Prec: {prec:.4f} | "
        f"Rec: {rec:.4f} | F1: {f1:.4f} | AUC: {auc:.4f}"
    )
    return metrics


def train_and_evaluate(
    max_train_plans: int = 3000,
    max_val_plans: int = 1000,
    max_test_plans: int = 1000,
) -> Dict:
    """Executes the full data loading, featurization, training, and evaluation workflow."""
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)

    t0 = time.time()
    logger.info("=== 1. Loading Real ResPlan Data Splits ===")
    train_plans = load_resplan_split(os.path.join(DATA_DIR, "train.jsonl"), max_plans=max_train_plans)
    val_plans = load_resplan_split(os.path.join(DATA_DIR, "val.jsonl"), max_plans=max_val_plans)
    test_plans = load_resplan_split(os.path.join(DATA_DIR, "test.jsonl"), max_plans=max_test_plans)

    logger.info(
        f"Floor plans loaded: Train={len(train_plans)}, Val={len(val_plans)}, Test={len(test_plans)}"
    )

    logger.info("=== 2. Generating Pairwise Datasets ===")
    train_df = build_pairwise_dataframe(train_plans)
    val_df = build_pairwise_dataframe(val_plans)
    test_df = build_pairwise_dataframe(test_plans)

    logger.info(
        f"Pair rows generated: Train={len(train_df)}, Val={len(val_df)}, Test={len(test_df)}"
    )

    # 3. Build & fit ColumnTransformer on Train split ONLY (preventing leakage)
    logger.info("=== 3. Fitting Preprocessing Pipeline on Training Data ===")
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERICAL_COLS),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL_COLS),
        ]
    )

    X_train = preprocessor.fit_transform(train_df[NUMERICAL_COLS + CATEGORICAL_COLS])
    X_val = preprocessor.transform(val_df[NUMERICAL_COLS + CATEGORICAL_COLS])
    X_test = preprocessor.transform(test_df[NUMERICAL_COLS + CATEGORICAL_COLS])

    # Targets: Door connectivity and wall adjacency
    y_train_door = train_df["is_connected"].values
    y_val_door = val_df["is_connected"].values
    y_test_door = test_df["is_connected"].values

    y_train_adj = train_df["is_adjacent"].values
    y_val_adj = val_df["is_adjacent"].values
    y_test_adj = test_df["is_adjacent"].values

    all_results = {}

    # 4. Train Target 1: Door Connectivity Model
    logger.info("=== 4. Training Models for Door Connectivity (is_connected) ===")
    # Baseline A: Dummy majority
    dummy_door = DummyClassifier(strategy="most_frequent")
    dummy_door.fit(X_train, y_train_door)
    all_results["dummy_door"] = evaluate_model(dummy_door, X_test, y_test_door, "Dummy Majority", "is_connected")

    # Baseline B: Logistic Regression
    lr_door = LogisticRegression(max_iter=500, random_state=42)
    lr_door.fit(X_train, y_train_door)
    all_results["lr_door"] = evaluate_model(lr_door, X_test, y_test_door, "Logistic Regression", "is_connected")

    # Primary Model: Random Forest
    rf_door = RandomForestClassifier(
        n_estimators=100,
        max_depth=12,
        min_samples_split=10,
        random_state=42,
        n_jobs=-1,
    )
    rf_door.fit(X_train, y_train_door)
    all_results["rf_door"] = evaluate_model(rf_door, X_test, y_test_door, "Random Forest", "is_connected")

    # 5. Train Target 2: Wall Adjacency Model
    logger.info("=== 5. Training Models for Wall Adjacency (is_adjacent) ===")
    dummy_adj = DummyClassifier(strategy="most_frequent")
    dummy_adj.fit(X_train, y_train_adj)
    all_results["dummy_adj"] = evaluate_model(dummy_adj, X_test, y_test_adj, "Dummy Majority", "is_adjacent")

    lr_adj = LogisticRegression(max_iter=500, random_state=42)
    lr_adj.fit(X_train, y_train_adj)
    all_results["lr_adj"] = evaluate_model(lr_adj, X_test, y_test_adj, "Logistic Regression", "is_adjacent")

    rf_adj = RandomForestClassifier(
        n_estimators=100,
        max_depth=12,
        min_samples_split=10,
        random_state=42,
        n_jobs=-1,
    )
    rf_adj.fit(X_train, y_train_adj)
    all_results["rf_adj"] = evaluate_model(rf_adj, X_test, y_test_adj, "Random Forest", "is_adjacent")

    # 6. Slice-based error analysis on test split for RF Door
    logger.info("=== 6. Computing Slice-Based Error Analysis ===")
    test_df_copy = test_df.copy()
    test_df_copy["pred_door"] = rf_door.predict(X_test)
    test_df_copy["pred_adj"] = rf_adj.predict(X_test)

    top_pairs = test_df_copy["pair_type"].value_counts().head(8).index.tolist()
    slice_analysis = {}
    for pt in top_pairs:
        mask = (test_df_copy["pair_type"] == pt).values
        sub_y_true = y_test_door[mask]
        sub_y_pred = test_df_copy.loc[mask, "pred_door"].values
        slice_analysis[pt] = {
            "sample_count": int(sum(mask)),
            "true_positive_rate": round(float(np.mean(sub_y_true)), 4),
            "precision": round(float(precision_score(sub_y_true, sub_y_pred, zero_division=0)), 4),
            "recall": round(float(recall_score(sub_y_true, sub_y_pred, zero_division=0)), 4),
            "f1_score": round(float(f1_score(sub_y_true, sub_y_pred, zero_division=0)), 4),
        }
    all_results["slice_analysis_door"] = slice_analysis

    # 7. Feature importances from Random Forest models
    feature_names = []
    # numerical
    feature_names.extend(NUMERICAL_COLS)
    # one-hot categorical
    ohe = preprocessor.named_transformers_["cat"]
    feature_names.extend(ohe.get_feature_names_out(CATEGORICAL_COLS).tolist())

    importances_door = [
        {"feature": name, "importance": round(float(imp), 4)}
        for name, imp in sorted(zip(feature_names, rf_door.feature_importances_), key=lambda x: x[1], reverse=True)[:15]
    ]
    all_results["top_features_door"] = importances_door

    # 8. Save Artifacts
    logger.info("=== 7. Saving Model Artifacts & Schemas ===")
    joblib.dump(preprocessor, os.path.join(ARTIFACTS_DIR, "preprocessor.joblib"))
    joblib.dump(rf_door, os.path.join(ARTIFACTS_DIR, "rf_door_model.joblib"))
    joblib.dump(rf_adj, os.path.join(ARTIFACTS_DIR, "rf_adj_model.joblib"))
    joblib.dump(lr_door, os.path.join(ARTIFACTS_DIR, "lr_door_model.joblib"))
    joblib.dump(lr_adj, os.path.join(ARTIFACTS_DIR, "lr_adj_model.joblib"))

    schema_info = {
        "dataset_name": "ResPlan-FP",
        "dataset_source": "https://huggingface.co/datasets/Tristan12138/resplan-fp",
        "license": "CC-BY-4.0",
        "splits": {
            "train_plans": len(train_plans),
            "val_plans": len(val_plans),
            "test_plans": len(test_plans),
            "train_pairs": len(train_df),
            "val_pairs": len(val_df),
            "test_pairs": len(test_df),
        },
        "numerical_features": NUMERICAL_COLS,
        "categorical_features": CATEGORICAL_COLS,
        "total_transformed_features": len(feature_names),
        "targets": ["is_connected", "is_adjacent"],
        "training_time_seconds": round(time.time() - t0, 2),
    }

    with open(os.path.join(ARTIFACTS_DIR, "feature_schema.json"), "w", encoding="utf-8") as f:
        json.dump(schema_info, f, indent=2)

    with open(os.path.join(ARTIFACTS_DIR, "evaluation_metrics.json"), "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)

    logger.info(f"Training and evaluation complete in {round(time.time() - t0, 2)}s!")
    return all_results


if __name__ == "__main__":
    train_and_evaluate()
