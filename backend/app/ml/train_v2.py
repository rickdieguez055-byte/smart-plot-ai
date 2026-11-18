"""Production training, optimization, and validation pipeline for SmartPlot ML V2.

Phase 5B enhancements:
- Trained on full ResPlan-FP dataset (14,958 valid training floor plans).
- Investigates and resolves door recall limitations via class weighting and threshold tuning.
- Hyperparameter tuning and probability calibration evaluated strictly on validation split.
- Final evaluation conducted once on held-out test split.
- Preserves baseline V1 artifacts in v1_baseline/ and saves V2 models independently.
"""
import json
import logging
import os
import sys
import time
from typing import Any, Dict, List, Tuple

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

import joblib
import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from backend.app.ml.dataset import build_pairwise_dataframe, load_resplan_split
from backend.app.ml.train import CATEGORICAL_COLS, NUMERICAL_COLS

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("smartplot.ml.train_v2")

ARTIFACTS_DIR = os.path.join(os.path.dirname(__file__), "artifacts")
DATA_DIR = os.path.join("data", "resplan")


def evaluate_predictions(
    y_true: np.ndarray,
    probs: np.ndarray,
    threshold: float = 0.5,
) -> Dict[str, Any]:
    """Calculates comprehensive classification metrics for given probability predictions and threshold."""
    preds = (probs >= threshold).astype(int)
    cm = confusion_matrix(y_true, preds)
    tn, fp, fn, tp = cm.ravel() if cm.size == 4 else (0, 0, 0, 0)

    acc = float(accuracy_score(y_true, preds))
    prec = float(precision_score(y_true, preds, zero_division=0))
    rec = float(recall_score(y_true, preds, zero_division=0))
    f1 = float(f1_score(y_true, preds, zero_division=0))
    auc = float(roc_auc_score(y_true, probs))
    brier = float(brier_score_loss(y_true, probs))

    return {
        "threshold": round(threshold, 3),
        "accuracy": round(acc, 4),
        "precision": round(prec, 4),
        "recall": round(rec, 4),
        "f1_score": round(f1, 4),
        "roc_auc": round(auc, 4),
        "brier_score": round(brier, 4),
        "confusion_matrix": {
            "true_negatives": int(tn),
            "false_positives": int(fp),
            "false_negatives": int(fn),
            "true_positives": int(tp),
        },
    }


def find_optimal_threshold(
    y_true: np.ndarray,
    probs: np.ndarray,
    metric: str = "f1",
) -> Tuple[float, Dict[str, Any]]:
    """Scans decision thresholds on validation data to maximize the specified metric."""
    best_thresh = 0.5
    best_score = -1.0
    best_metrics = {}

    thresholds = np.arange(0.20, 0.65, 0.02)
    for t in thresholds:
        m = evaluate_predictions(y_true, probs, threshold=t)
        score = m["f1_score"] if metric == "f1" else (m["precision"] + m["recall"]) / 2
        if score > best_score:
            best_score = score
            best_thresh = float(t)
            best_metrics = m

    return best_thresh, best_metrics


def slice_evaluate(
    df: pd.DataFrame,
    probs: np.ndarray,
    target_col: str,
    threshold: float = 0.5,
) -> Dict[str, Any]:
    """Evaluates performance across architectural pair slices (e.g. bathroom_bedroom)."""
    preds = (probs >= threshold).astype(int)
    slices = {}
    top_slices = ["bathroom_bedroom", "bedroom_living", "bathroom_living", "bedroom_bedroom", "kitchen_living"]

    for stype in top_slices:
        mask = (df["pair_type"] == stype).values
        if mask.sum() == 0:
            continue
        y_slice = df.loc[mask, target_col].values
        p_slice = preds[mask]
        total = int(len(y_slice))
        pos = int(y_slice.sum())

        rec = float(recall_score(y_slice, p_slice, zero_division=0))
        prec = float(precision_score(y_slice, p_slice, zero_division=0))
        f1 = float(f1_score(y_slice, p_slice, zero_division=0))

        slices[stype] = {
            "total_samples": total,
            "positive_count": pos,
            "positive_rate": round(pos / total, 4) if total > 0 else 0.0,
            "precision": round(prec, 4),
            "recall": round(rec, 4),
            "f1_score": round(f1, 4),
        }

    return slices


def run_phase5b_training():
    logger.info("=== SMARTPLOT AI PHASE 5B: MODEL OPTIMIZATION PIPELINE ===")

    train_path = os.path.join(DATA_DIR, "train_full.jsonl")
    val_path = os.path.join(DATA_DIR, "val.jsonl")
    test_path = os.path.join(DATA_DIR, "test.jsonl")

    # 1. Load splits
    logger.info("Loading full training split...")
    train_plans = load_resplan_split(train_path)
    train_df = build_pairwise_dataframe(train_plans)
    logger.info(f"Loaded {len(train_plans)} training plans -> {len(train_df)} pairwise instances.")

    logger.info("Loading validation split...")
    val_plans = load_resplan_split(val_path)
    val_df = build_pairwise_dataframe(val_plans)
    logger.info(f"Loaded {len(val_plans)} validation plans -> {len(val_df)} pairwise instances.")

    logger.info("Loading held-out test split...")
    test_plans = load_resplan_split(test_path)
    test_df = build_pairwise_dataframe(test_plans)
    logger.info(f"Loaded {len(test_plans)} test plans -> {len(test_df)} pairwise instances.")

    feature_cols = NUMERICAL_COLS + CATEGORICAL_COLS

    # 2. Fit preprocessor strictly on training data
    logger.info("Fitting ColumnTransformer exclusively on training split...")
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERICAL_COLS),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL_COLS),
        ]
    )
    X_train = preprocessor.fit_transform(train_df[feature_cols])
    X_val = preprocessor.transform(val_df[feature_cols])
    X_test = preprocessor.transform(test_df[feature_cols])

    y_train_door = train_df["is_connected"].values
    y_val_door = val_df["is_connected"].values
    y_test_door = test_df["is_connected"].values

    y_train_adj = train_df["is_adjacent"].values
    y_val_adj = val_df["is_adjacent"].values
    y_test_adj = test_df["is_adjacent"].values

    logger.info(f"Feature matrix shapes: Train={X_train.shape}, Val={X_val.shape}, Test={X_test.shape}")

    # =========================================================================
    # EXPERIMENT 1: Hyperparameter & Class Weight Search on Validation Split
    # =========================================================================
    logger.info("\n--- STEP 1: VALIDATION EXPERIMENTS (DOOR CONNECTIVITY) ---")
    experiments = [
        {"name": "rf_v1_repro", "n_est": 100, "max_depth": 12, "min_split": 10, "cw": None},
        {"name": "rf_balanced", "n_est": 100, "max_depth": 12, "min_split": 10, "cw": "balanced"},
        {"name": "rf_depth16_balanced", "n_est": 100, "max_depth": 16, "min_split": 10, "cw": "balanced"},
        {"name": "rf_depth16_subsample", "n_est": 150, "max_depth": 16, "min_split": 5, "cw": "balanced_subsample"},
        {"name": "rf_custom_weight", "n_est": 100, "max_depth": 14, "min_split": 8, "cw": {0: 1.0, 1: 1.8}},
    ]

    val_results = {}
    fitted_models = {}

    for exp in experiments:
        t0 = time.time()
        rf = RandomForestClassifier(
            n_estimators=exp["n_est"],
            max_depth=exp["max_depth"],
            min_samples_split=exp["min_split"],
            class_weight=exp["cw"],
            random_state=42,
            n_jobs=-1,
        )
        rf.fit(X_train, y_train_door)
        fit_time = time.time() - t0

        probs_val = rf.predict_proba(X_val)[:, 1]
        m_default = evaluate_predictions(y_val_door, probs_val, threshold=0.5)

        # Optimize threshold strictly on validation set
        opt_thresh, m_opt = find_optimal_threshold(y_val_door, probs_val, metric="f1")
        slices_opt = slice_evaluate(val_df, probs_val, "is_connected", threshold=opt_thresh)

        logger.info(
            f"Exp '{exp['name']}' (fit {fit_time:.1f}s): "
            f"Val @0.5 -> Acc={m_default['accuracy']}, Rec={m_default['recall']}, F1={m_default['f1_score']} | "
            f"Val @{opt_thresh:.2f} -> Acc={m_opt['accuracy']}, Rec={m_opt['recall']}, Prec={m_opt['precision']}, F1={m_opt['f1_score']} | "
            f"Bath-Bed Rec={slices_opt.get('bathroom_bedroom', {}).get('recall', 0.0)}"
        )

        val_results[exp["name"]] = {
            "config": exp,
            "fit_time_seconds": round(fit_time, 2),
            "metrics_at_0.5": m_default,
            "metrics_at_optimal_threshold": m_opt,
            "optimal_threshold": opt_thresh,
            "slices": slices_opt,
        }
        fitted_models[exp["name"]] = rf

    # Select best door model based on Validation F1 at optimal threshold
    best_door_name = max(val_results.keys(), key=lambda k: val_results[k]["metrics_at_optimal_threshold"]["f1_score"])
    best_door_rf = fitted_models[best_door_name]
    best_door_thresh = val_results[best_door_name]["optimal_threshold"]
    logger.info(f"\n>>> Best Door Model on Validation: '{best_door_name}' with threshold {best_door_thresh:.2f}")

    # =========================================================================
    # EXPERIMENT 2: Probability Calibration (Platt Scaling on Validation Set)
    # =========================================================================
    logger.info("\n--- STEP 2: PROBABILITY CALIBRATION (PLATT SCALING) ---")
    probs_val_best = best_door_rf.predict_proba(X_val)[:, 1]
    calibrator = LogisticRegression(C=1.0)
    calibrator.fit(probs_val_best.reshape(-1, 1), y_val_door)

    probs_val_cal = calibrator.predict_proba(probs_val_best.reshape(-1, 1))[:, 1]
    m_val_cal = evaluate_predictions(y_val_door, probs_val_cal, threshold=0.5)
    opt_thresh_cal, m_val_cal_opt = find_optimal_threshold(y_val_door, probs_val_cal, metric="f1")
    logger.info(
        f"Calibrated Door Model on Val: Brier={m_val_cal['brier_score']} (uncal={val_results[best_door_name]['metrics_at_0.5']['brier_score']}), "
        f"F1@opt={m_val_cal_opt['f1_score']} (thresh={opt_thresh_cal:.2f})"
    )

    # =========================================================================
    # STEP 3: Train Wall Adjacency Model V2
    # =========================================================================
    logger.info("\n--- STEP 3: WALL ADJACENCY MODEL V2 ---")
    rf_adj = RandomForestClassifier(
        n_estimators=100,
        max_depth=16,
        min_samples_split=8,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )
    t0 = time.time()
    rf_adj.fit(X_train, y_train_adj)
    adj_fit_time = time.time() - t0

    probs_val_adj = rf_adj.predict_proba(X_val)[:, 1]
    opt_adj_thresh, m_val_adj_opt = find_optimal_threshold(y_val_adj, probs_val_adj, metric="f1")
    logger.info(
        f"Adjacency Model V2 fit in {adj_fit_time:.1f}s: "
        f"Val @{opt_adj_thresh:.2f} -> Acc={m_val_adj_opt['accuracy']}, Rec={m_val_adj_opt['recall']}, Prec={m_val_adj_opt['precision']}, F1={m_val_adj_opt['f1_score']}"
    )

    # =========================================================================
    # STEP 4: FINAL TEST EVALUATION (SINGLE RUN ON HELD-OUT TEST SPLIT)
    # =========================================================================
    logger.info("\n--- STEP 4: FINAL EVALUATION ON UNSEEN HELD-OUT TEST SET ---")

    # Evaluate Door Model on Test
    probs_test_door = best_door_rf.predict_proba(X_test)[:, 1]
    test_door_at_05 = evaluate_predictions(y_test_door, probs_test_door, threshold=0.5)
    test_door_at_opt = evaluate_predictions(y_test_door, probs_test_door, threshold=best_door_thresh)
    test_door_slices = slice_evaluate(test_df, probs_test_door, "is_connected", threshold=best_door_thresh)

    # Evaluate Calibrated Door Model on Test
    probs_test_door_cal = calibrator.predict_proba(probs_test_door.reshape(-1, 1))[:, 1]
    test_door_cal_at_05 = evaluate_predictions(y_test_door, probs_test_door_cal, threshold=0.5)
    test_door_cal_at_opt = evaluate_predictions(y_test_door, probs_test_door_cal, threshold=opt_thresh_cal)

    # Evaluate Adjacency Model on Test
    probs_test_adj = rf_adj.predict_proba(X_test)[:, 1]
    test_adj_at_05 = evaluate_predictions(y_test_adj, probs_test_adj, threshold=0.5)
    test_adj_at_opt = evaluate_predictions(y_test_adj, probs_test_adj, threshold=opt_adj_thresh)
    test_adj_slices = slice_evaluate(test_df, probs_test_adj, "is_adjacent", threshold=opt_adj_thresh)

    logger.info("================ FINAL TEST RESULTS ================")
    logger.info(f"DOOR CONNECTIVITY (V2 @ optimal threshold {best_door_thresh:.2f}):")
    logger.info(
        f"  Accuracy:  {test_door_at_opt['accuracy']} (vs V1 baseline 0.8683)"
    )
    logger.info(
        f"  Precision: {test_door_at_opt['precision']} (vs V1 baseline 0.9359)"
    )
    logger.info(
        f"  Recall:    {test_door_at_opt['recall']} (vs V1 baseline 0.6199 -> +{(test_door_at_opt['recall'] - 0.6199)*100:.1f}%)"
    )
    logger.info(
        f"  F1 Score:  {test_door_at_opt['f1_score']} (vs V1 baseline 0.7458 -> +{(test_door_at_opt['f1_score'] - 0.7458)*100:.1f}%)"
    )
    logger.info(
        f"  ROC-AUC:   {test_door_at_opt['roc_auc']} (vs V1 baseline 0.9299)"
    )
    logger.info(f"  Confusion Matrix: {test_door_at_opt['confusion_matrix']}")
    logger.info(
        f"  Bathroom-Bedroom Door Recall: {test_door_slices.get('bathroom_bedroom', {}).get('recall', 0.0)} (vs V1 baseline 0.0000)"
    )

    logger.info(f"\nWALL ADJACENCY (V2 @ optimal threshold {opt_adj_thresh:.2f}):")
    logger.info(
        f"  Accuracy:  {test_adj_at_opt['accuracy']} (vs V1 baseline 0.7488)"
    )
    logger.info(
        f"  Precision: {test_adj_at_opt['precision']} (vs V1 baseline 0.8323)"
    )
    logger.info(
        f"  Recall:    {test_adj_at_opt['recall']} (vs V1 baseline 0.6554 -> +{(test_adj_at_opt['recall'] - 0.6554)*100:.1f}%)"
    )
    logger.info(
        f"  F1 Score:  {test_adj_at_opt['f1_score']} (vs V1 baseline 0.7334 -> +{(test_adj_at_opt['f1_score'] - 0.7334)*100:.1f}%)"
    )
    logger.info(
        f"  ROC-AUC:   {test_adj_at_opt['roc_auc']} (vs V1 baseline 0.8363)"
    )

    # Save V2 artifacts independently
    logger.info("\n--- SAVING V2 ARTIFACTS ---")
    joblib.dump(preprocessor, os.path.join(ARTIFACTS_DIR, "preprocessor_v2.joblib"))
    joblib.dump(best_door_rf, os.path.join(ARTIFACTS_DIR, "rf_door_v2.joblib"))
    joblib.dump(calibrator, os.path.join(ARTIFACTS_DIR, "rf_door_calibrated_v2.joblib"))
    joblib.dump(rf_adj, os.path.join(ARTIFACTS_DIR, "rf_adj_v2.joblib"))

    thresholds_config = {
        "door_optimal_threshold": best_door_thresh,
        "door_calibrated_threshold": opt_thresh_cal,
        "adjacency_optimal_threshold": opt_adj_thresh,
        "best_door_config": val_results[best_door_name]["config"],
    }
    with open(os.path.join(ARTIFACTS_DIR, "v2_thresholds.json"), "w", encoding="utf-8") as f:
        json.dump(thresholds_config, f, indent=2)

    v2_metrics = {
        "dataset_info": {
            "training_plans": len(train_plans),
            "training_pairs": len(train_df),
            "validation_plans": len(val_plans),
            "validation_pairs": len(val_df),
            "test_plans": len(test_plans),
            "test_pairs": len(test_df),
        },
        "validation_experiments": val_results,
        "test_evaluation": {
            "door_v2_at_05": test_door_at_05,
            "door_v2_at_optimal_threshold": test_door_at_opt,
            "door_v2_calibrated_at_05": test_door_cal_at_05,
            "door_v2_calibrated_at_optimal": test_door_cal_at_opt,
            "door_v2_slices": test_door_slices,
            "adj_v2_at_05": test_adj_at_05,
            "adj_v2_at_optimal_threshold": test_adj_at_opt,
            "adj_v2_slices": test_adj_slices,
        },
    }
    with open(os.path.join(ARTIFACTS_DIR, "v2_evaluation_metrics.json"), "w", encoding="utf-8") as f:
        json.dump(v2_metrics, f, indent=2)

    logger.info("Successfully trained, validated, and saved SmartPlot AI ML V2!")


if __name__ == "__main__":
    run_phase5b_training()
