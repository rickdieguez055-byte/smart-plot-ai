"""Room category taxonomy and semantic label mapping between real datasets (ResPlan) and SmartPlot."""
from typing import Dict, Optional, Set

# SmartPlot canonical categories
CANONICAL_CATEGORIES = [
    "living",
    "bedroom",
    "bathroom",
    "kitchen",
    "parking",
    "utility",
]

# Raw ResPlan / standard architectural label mapping
RESPLAN_LABEL_MAP: Dict[str, str] = {
    "LIVING": "living",
    "LIVING_ROOM": "living",
    "DINING": "living",
    "DRAWING": "living",
    "HALL": "living",
    "LOUNGE": "living",
    "FAMILY": "living",
    "BEDROOM": "bedroom",
    "MASTER_BEDROOM": "bedroom",
    "BED": "bedroom",
    "ROOM": "bedroom",
    "GUEST": "bedroom",
    "BATH": "bathroom",
    "BATHROOM": "bathroom",
    "WC": "bathroom",
    "TOILET": "bathroom",
    "POWDER": "bathroom",
    "KITCHEN": "kitchen",
    "PANTRY": "kitchen",
    "COOKING": "kitchen",
    "BALCONY": "parking",  # Exterior open-to-sky buffer
    "TERRACE": "parking",
    "PORCH": "parking",
    "CAR_PORCH": "parking",
    "GARAGE": "parking",
    "PARKING": "parking",
    "UTILITY": "utility",
    "STORE": "utility",
    "LAUNDRY": "utility",
    "STORAGE": "utility",
}


def map_room_label(raw_label: str) -> str:
    """Normalizes an architectural dataset room label to SmartPlot canonical category."""
    cleaned = raw_label.strip().upper().replace(" ", "_").replace("-", "_")
    return RESPLAN_LABEL_MAP.get(cleaned, "bedroom" if "BED" in cleaned else "utility")
