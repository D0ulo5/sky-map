#!/usr/bin/env python3
"""
Parse the Yale Bright Star Catalog (gzipped fixed-width) and merge it
with IAU proper-star names and metadata.

Sources:
- data/catalog.dat.gz
    Astronomical data such as coordinates, magnitude and spectral type.
- data/iau_proper_stars.csv
    IAU proper names, designations, constellation information and
    name-origin metadata.

Output:
- assets/data/stars.json
"""

import csv
import gzip
import json
import sys
from pathlib import Path
from typing import Optional, List, Dict, Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent

CACHE_FILE = PROJECT_ROOT / "data" / "catalog.dat.gz"
COMMON_NAMES_FILE = PROJECT_ROOT / "data" / "iau_proper_stars.csv"
OUTPUT_FILE = PROJECT_ROOT / "assets" / "data" / "stars.json"


# ---------------------------------------------------------------------------
# Yale Bright Star Catalog fixed-width fields
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_float(value: str) -> Optional[float]:
    """Parse a floating-point value, returning None for empty fields."""
    stripped = value.strip()

    if not stripped:
        return None

    try:
        return float(stripped)
    except ValueError:
        return None


def parse_int(value: str) -> Optional[int]:
    """Parse an integer value, returning None for empty/invalid fields."""
    stripped = value.strip()

    if not stripped:
        return None

    try:
        return int(stripped)
    except ValueError:
        return None


def parse_ra(hours: float, minutes: float, seconds: float) -> float:
    """Convert right ascension from HMS to decimal degrees."""
    if hours == 24:
        hours = 0.0

    return (
        hours
        + minutes / 60.0
        + seconds / 3600.0
    ) * 15.0


def parse_dec(
    sign: str,
    degrees: float,
    minutes: float,
    seconds: float,
) -> float:
    """Convert declination from DMS to decimal degrees."""
    value = degrees + minutes / 60.0 + seconds / 3600.0

    return -value if sign == "-" else value


def clean(value: Optional[str]) -> Optional[str]:
    """Strip a CSV value and convert empty strings to None."""
    if value is None:
        return None

    value = value.strip()

    return value if value else None


# ---------------------------------------------------------------------------
# IAU proper-star metadata
# ---------------------------------------------------------------------------

def load_iau_stars() -> Dict[str, Dict[str, Any]]:
    """
    Load IAU proper-star metadata indexed by HR designation.

    The CSV contains:
        Proper Names
        NEC+
        Designation
        HIP
        Bayer ID
        Simbad spelling
        Constellation
        Origin
        Language
        Reference
        Date of Adoption
    """

    stars: Dict[str, Dict[str, Any]] = {}

    if not COMMON_NAMES_FILE.exists():
        print(
            f"Warning: IAU proper names file not found: "
            f"{COMMON_NAMES_FILE}",
            file=sys.stderr,
        )
        return stars

    with COMMON_NAMES_FILE.open(
        "r",
        encoding="utf-8",
        newline="",
    ) as file:
        reader = csv.DictReader(file)

        for row in reader:
            designation = clean(row.get("Designation"))

            if not designation:
                continue

            # We currently merge using HR numbers because the Yale
            # Bright Star Catalog uses HR as its primary identifier.
            if not designation.startswith("HR "):
                continue

            hr = designation[3:].strip()

            if not hr.isdigit():
                continue

            stars[hr] = {
                "common_name": clean(row.get("Proper Names")),
                "hip": parse_int(row.get("HIP", "")),
                "bayer": clean(row.get("Bayer ID")),
                "constellation": clean(row.get("Constellation")),
                "origin": clean(row.get("Origin")),
                "language": clean(row.get("Language")),
                "reference": clean(row.get("Reference")),
                "date_of_adoption": clean(row.get("Date of Adoption")),
            }

    return stars


# ---------------------------------------------------------------------------
# Yale Bright Star Catalog
# ---------------------------------------------------------------------------

def parse_star_line(
    line: str,
    iau_stars: Dict[str, Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """Parse one fixed-width Yale Bright Star Catalog record."""

    hr = line[HR_START:HR_END].strip()

    if not hr:
        return None

    try:
        star_id = int(hr)
    except ValueError:
        return None

    # -----------------------------------------------------------------------
    # Apparent magnitude
    # -----------------------------------------------------------------------

    vmag = parse_float(line[VMAG_START:VMAG_END])

    if vmag is None:
        return None

    # -----------------------------------------------------------------------
    # Right ascension
    # -----------------------------------------------------------------------

    ra_hours = parse_float(
        line[RA_HOURS_START:RA_HOURS_END]
    )

    ra_minutes = parse_float(
        line[RA_MINUTES_START:RA_MINUTES_END]
    )

    ra_seconds = parse_float(
        line[RA_SECONDS_START:RA_SECONDS_END]
    )

    if None in (ra_hours, ra_minutes, ra_seconds):
        return None

    # -----------------------------------------------------------------------
    # Declination
    # -----------------------------------------------------------------------

    dec_sign = line[DEC_SIGN_START:DEC_SIGN_END]

    dec_degrees = parse_float(
        line[DEC_DEGREES_START:DEC_DEGREES_END]
    )

    dec_minutes = parse_float(
        line[DEC_MINUTES_START:DEC_MINUTES_END]
    )

    dec_seconds = parse_float(
        line[DEC_SECONDS_START:DEC_SECONDS_END]
    )

    if None in (dec_degrees, dec_minutes, dec_seconds):
        return None

    if dec_sign not in ("+", "-"):
        return None

    # -----------------------------------------------------------------------
    # Validate RA
    # -----------------------------------------------------------------------

    if not (
        0 <= ra_hours <= 24
        and 0 <= ra_minutes < 60
        and 0 <= ra_seconds < 60
    ):
        return None

    if ra_hours == 24 and (
        ra_minutes != 0 or ra_seconds != 0
    ):
        return None

    # -----------------------------------------------------------------------
    # Validate declination
    # -----------------------------------------------------------------------

    if not (
        0 <= dec_degrees <= 90
        and 0 <= dec_minutes < 60
        and 0 <= dec_seconds < 60
    ):
        return None

    dec_abs = (
        dec_degrees
        + dec_minutes / 60.0
        + dec_seconds / 3600.0
    )

    if dec_abs > 90:
        return None

    if dec_degrees == 90 and (
        dec_minutes != 0 or dec_seconds != 0
    ):
        return None

    # -----------------------------------------------------------------------
    # Convert coordinates
    # -----------------------------------------------------------------------

    ra = parse_ra(
        ra_hours,
        ra_minutes,
        ra_seconds,
    )

    dec = parse_dec(
        dec_sign,
        dec_degrees,
        dec_minutes,
        dec_seconds,
    )

    # -----------------------------------------------------------------------
    # Basic catalog information
    # -----------------------------------------------------------------------

    name = clean(
        line[NAME_START:NAME_END]
    )

    spectral_type = clean(
        line[SPECTRAL_START:SPECTRAL_END]
    )

    # -----------------------------------------------------------------------
    # IAU metadata
    # -----------------------------------------------------------------------

    iau = iau_stars.get(str(star_id), {})

    return {
        "id": star_id,

        # Existing fields
        "name": name,
        "common_name": iau.get("common_name"),
        "magnitude": round(vmag, 2),
        "spectral_type": spectral_type,
        "ra": round(ra, 6),
        "dec": round(dec, 6),

        # IAU metadata
        "hip": iau.get("hip"),
        "bayer": iau.get("bayer"),
        "constellation": iau.get("constellation"),
        "origin": iau.get("origin"),
        "language": iau.get("language"),
        "reference": iau.get("reference"),
        "date_of_adoption": iau.get("date_of_adoption"),
    }


def parse_catalog(
    iau_stars: Dict[str, Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """Parse the complete Yale Bright Star Catalog."""

    stars: List[Dict[str, Any]] = []

    with gzip.open(
        CACHE_FILE,
        "rt",
        encoding="ascii",
        errors="replace",
    ) as file:

        for line in file:
            if len(line) < MIN_LINE_LENGTH:
                continue

            if not line.strip():
                continue

            star = parse_star_line(
                line,
                iau_stars,
            )

            if star is not None:
                stars.append(star)

    return stars


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def write_catalog(
    stars: List[Dict[str, Any]],
) -> None:
    """Write the generated star catalogue to JSON."""

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            stars,
            file,
            indent=2,
            ensure_ascii=False,
        )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if not CACHE_FILE.exists():
        print(
            f"Catalog not found: {CACHE_FILE}",
            file=sys.stderr,
        )
        sys.exit(1)

    print("Loading IAU proper-star metadata...")

    iau_stars = load_iau_stars()

    print(
        f"Loaded {len(iau_stars)} IAU star entries."
    )

    print("Parsing Yale Bright Star Catalog...")

    stars = parse_catalog(iau_stars)

    print(
        f"Parsed {len(stars)} stars."
    )

    named_stars = sum(
        1
        for star in stars
        if star["common_name"]
    )

    print(
        f"Matched {named_stars} IAU proper names."
    )

    stars_with_constellations = sum(
        1
        for star in stars
        if star["constellation"]
    )

    print(
        "Matched "
        f"{stars_with_constellations} "
        "constellation assignments."
    )

    stars_with_descriptions = sum(
        1
        for star in stars
        if star["origin"]
    )

    print(
        "Matched "
        f"{stars_with_descriptions} "
        "star name origins/descriptions."
    )

    print(
        f"Writing catalog to: {OUTPUT_FILE}"
    )

    write_catalog(stars)

    print("Done.")


if __name__ == "__main__":
    main()