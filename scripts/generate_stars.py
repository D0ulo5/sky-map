#!/usr/bin/env python3
"""
Parse Yale Bright Star Catalog (gzipped fixed‑width) and output JSON.
"""

import gzip
import json
import sys
from pathlib import Path
from typing import Optional, List, Dict, Any

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CACHE_FILE = PROJECT_ROOT / "data" / "catalog.dat.gz"
OUTPUT_FILE = PROJECT_ROOT / "assets" / "data" / "stars.json"

# Fixed‑width field offsets (0‑based)
HR_START, HR_END = 0, 4
NAME_START, NAME_END = 4, 14
RA_HOURS_START, RA_HOURS_END = 75, 77
RA_MINUTES_START, RA_MINUTES_END = 77, 79
RA_SECONDS_START, RA_SECONDS_END = 79, 83
DEC_SIGN_START, DEC_SIGN_END = 83, 84
DEC_DEGREES_START, DEC_DEGREES_END = 84, 86
DEC_MINUTES_START, DEC_MINUTES_END = 86, 88
DEC_SECONDS_START, DEC_SECONDS_END = 88, 90
VMAG_START, VMAG_END = 102, 107
SPECTRAL_START, SPECTRAL_END = 127, 147
MIN_LINE_LENGTH = SPECTRAL_END


def parse_float(value: str) -> Optional[float]:
    stripped = value.strip()
    return float(stripped) if stripped else None


def parse_ra(hours: float, minutes: float, seconds: float) -> float:
    if hours == 24:
        hours = 0.0
    return (hours + minutes / 60.0 + seconds / 3600.0) * 15.0


def parse_dec(sign: str, degrees: float, minutes: float, seconds: float) -> float:
    value = degrees + minutes / 60.0 + seconds / 3600.0
    return -value if sign == "-" else value


def parse_star_line(line: str) -> Optional[Dict[str, Any]]:
    hr = line[HR_START:HR_END].strip()
    if not hr:
        return None
    try:
        star_id = int(hr)
    except ValueError:
        return None

    name = line[NAME_START:NAME_END].strip() or None

    vmag = parse_float(line[VMAG_START:VMAG_END])
    if vmag is None:
        return None

    ra_hours = parse_float(line[RA_HOURS_START:RA_HOURS_END])
    ra_minutes = parse_float(line[RA_MINUTES_START:RA_MINUTES_END])
    ra_seconds = parse_float(line[RA_SECONDS_START:RA_SECONDS_END])
    if None in (ra_hours, ra_minutes, ra_seconds):
        return None

    dec_sign = line[DEC_SIGN_START:DEC_SIGN_END]
    dec_degrees = parse_float(line[DEC_DEGREES_START:DEC_DEGREES_END])
    dec_minutes = parse_float(line[DEC_MINUTES_START:DEC_MINUTES_END])
    dec_seconds = parse_float(line[DEC_SECONDS_START:DEC_SECONDS_END])
    if None in (dec_degrees, dec_minutes, dec_seconds) or dec_sign not in ("+", "-"):
        return None

    # RA validation
    if not (0 <= ra_hours <= 24) or not (0 <= ra_minutes < 60) or not (0 <= ra_seconds < 60):
        return None
    if ra_hours == 24 and (ra_minutes != 0 or ra_seconds != 0):
        return None

    # Dec validation
    if not (0 <= dec_degrees <= 90) or not (0 <= dec_minutes < 60) or not (0 <= dec_seconds < 60):
        return None
    dec_abs = dec_degrees + dec_minutes / 60.0 + dec_seconds / 3600.0
    if dec_abs > 90 or (dec_degrees == 90 and (dec_minutes != 0 or dec_seconds != 0)):
        return None

    ra = parse_ra(ra_hours, ra_minutes, ra_seconds)
    dec = parse_dec(dec_sign, dec_degrees, dec_minutes, dec_seconds)
    spectral_type = line[SPECTRAL_START:SPECTRAL_END].strip() or None

    return {
        "id": star_id,
        "name": name,
        "magnitude": round(vmag, 2),
        "spectral_type": spectral_type,
        "ra": round(ra, 6),
        "dec": round(dec, 6),
    }


def parse_catalog() -> List[Dict[str, Any]]:
    stars = []
    with gzip.open(CACHE_FILE, "rt", encoding="ascii", errors="replace") as f:
        for line in f:
            if len(line) >= MIN_LINE_LENGTH and line.strip():
                star = parse_star_line(line)
                if star:
                    stars.append(star)
    return stars


def write_catalog(stars: List[Dict[str, Any]]) -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_FILE.open("w", encoding="utf-8") as f:
        json.dump(stars, f, indent=2, ensure_ascii=False)


def main() -> None:
    if not CACHE_FILE.exists():
        print(f"Catalog not found: {CACHE_FILE}", file=sys.stderr)
        sys.exit(1)

    print("Parsing star catalog...")
    stars = parse_catalog()
    print(f"Parsed {len(stars)} stars.")
    print(f"Writing catalog to: {OUTPUT_FILE}")
    write_catalog(stars)
    print("Done.")


if __name__ == "__main__":
    main()