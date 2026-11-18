"""Exhaustive dataset integrity, exclusion analysis, and fingerprinting for SmartPlot AI Phase 5B."""
import json
import os
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from backend.app.ml.dataset import compute_polygon_area
from backend.app.ml.taxonomy import map_room_label


def audit_split(file_path: str, split_name: str):
    print(f"\n=================== AUDITING {split_name.upper()} ({file_path}) ===================")
    total_lines = 0
    valid_plans = 0
    excluded_plans = []
    room_counts = []
    plan_ids = set()
    fingerprints = Counter()  # canonical category tuple -> count

    category_counts = Counter()
    door_pair_counts = Counter()
    adj_pair_counts = Counter()
    total_pairs = Counter()

    with open(file_path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            total_lines += 1
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            pid = data.get("id", f"unknown_{idx}")
            plan_ids.add(pid)

            gt = data.get("gt")
            if not gt or "rooms" not in gt or "walls" not in gt:
                excluded_plans.append({"line": idx, "id": pid, "reason": "missing gt/rooms/walls"})
                continue

            rooms = gt["rooms"]
            walls = {w["id"]: w for w in gt["walls"]}
            n_rooms = len(rooms)
            if n_rooms < 2:
                excluded_plans.append({"line": idx, "id": pid, "reason": f"insufficient rooms: {n_rooms} room(s)"})
                continue

            valid_plans += 1
            room_counts.append(n_rooms)

            cats = [map_room_label(r.get("label", "ROOM")) for r in rooms]
            for c in cats:
                category_counts[c] += 1
            fp = tuple(sorted(cats))
            fingerprints[fp] += 1

            # Check pairs
            for i in range(n_rooms):
                w_i = set(rooms[i].get("walls", []))
                for j in range(i + 1, n_rooms):
                    w_j = set(rooms[j].get("walls", []))
                    shared = w_i.intersection(w_j)
                    c1, c2 = sorted([cats[i], cats[j]])
                    ptype = f"{c1}_{c2}"
                    total_pairs[ptype] += 1

                    if shared:
                        adj_pair_counts[ptype] += 1
                        has_door = any(
                            any(op.get("type") == "door" for op in walls[wid].get("openings", []))
                            for wid in shared if wid in walls
                        )
                        if has_door:
                            door_pair_counts[ptype] += 1

    print(f"Total lines: {total_lines}")
    print(f"Valid plans: {valid_plans} ({(valid_plans/total_lines)*100:.2f}%)")
    print(f"Excluded plans: {len(excluded_plans)}")
    for ex in excluded_plans[:10]:
        print(f"   - Line {ex['line']}, ID '{ex['id']}': {ex['reason']}")
    if len(excluded_plans) > 10:
        print(f"   ... and {len(excluded_plans) - 10} more.")

    print(f"Room count per plan: min={min(room_counts)}, max={max(room_counts)}, avg={sum(room_counts)/len(room_counts):.2f}")
    print(f"Room category counts: {dict(category_counts)}")
    print(f"Top 5 architectural configurations (fingerprints):")
    for fp, count in fingerprints.most_common(5):
        print(f"   {fp}: {count} plans ({count/valid_plans*100:.1f}%)")

    print("\nPairwise Door & Adjacency Rates by Pair Type:")
    for ptype, tot in sorted(total_pairs.items(), key=lambda x: -x[1]):
        adj = adj_pair_counts[ptype]
        door = door_pair_counts[ptype]
        print(f"   {ptype:20s}: Total={tot:5d} | Adj={adj:5d} ({adj/tot*100:5.1f}%) | Door={door:5d} ({door/tot*100:5.1f}%)")

    return {
        "split": split_name,
        "total_lines": total_lines,
        "valid_plans": valid_plans,
        "excluded_plans": excluded_plans,
        "plan_ids": plan_ids,
        "fingerprints": fingerprints,
        "category_counts": category_counts,
        "door_pair_counts": door_pair_counts,
        "adj_pair_counts": adj_pair_counts,
        "total_pairs": total_pairs,
    }


if __name__ == "__main__":
    val_res = audit_split("data/resplan/val.jsonl", "validation")
    test_res = audit_split("data/resplan/test.jsonl", "test")
    train_res = audit_split("data/resplan/train.jsonl", "train (subset)")

    # Check ID overlaps
    train_val_overlap = train_res["plan_ids"].intersection(val_res["plan_ids"])
    train_test_overlap = train_res["plan_ids"].intersection(test_res["plan_ids"])
    val_test_overlap = val_res["plan_ids"].intersection(test_res["plan_ids"])

    print("\n=================== SPLIT SEPARATION AUDIT ===================")
    print(f"Train / Val ID overlap: {len(train_val_overlap)} (expected 0)")
    print(f"Train / Test ID overlap: {len(train_test_overlap)} (expected 0)")
    print(f"Val / Test ID overlap: {len(val_test_overlap)} (expected 0)")

    # Fingerprint overlap
    shared_fps = set(train_res["fingerprints"].keys()).intersection(set(test_res["fingerprints"].keys()))
    print(f"Unique functional fingerprints: Train={len(train_res['fingerprints'])}, Test={len(test_res['fingerprints'])}, Shared={len(shared_fps)}")
