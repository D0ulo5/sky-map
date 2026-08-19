#!/usr/bin/env python3
"""
Generate constellation data for Sky Map.

The source dataset contains constellation stick figures using
Yale Bright Star Catalog (HR) identifiers.

The generated JSON references the same HR identifiers used by
assets/data/stars.json.

This keeps constellation rendering independent from the
astronomical coordinate calculations performed by Flutter.
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set


PROJECT_ROOT = Path(__file__).resolve().parent.parent

SOURCE_FILE = (
    PROJECT_ROOT
    / "data"
    / "constellation_lines_hr.dat"
)

STARS_FILE = (
    PROJECT_ROOT
    / "assets"
    / "data"
    / "stars.json"
)

OUTPUT_FILE = (
    PROJECT_ROOT
    / "assets"
    / "data"
    / "constellations.json"
)


# ---------------------------------------------------------------------------
# IAU constellation names
# ---------------------------------------------------------------------------

CONSTELLATION_NAMES: Dict[str, str] = {
    "And": "Andromeda",
    "Ant": "Antlia",
    "Aps": "Apus",
    "Aqr": "Aquarius",
    "Aql": "Aquila",
    "Ara": "Ara",
    "Ari": "Aries",
    "Aur": "Auriga",
    "Boo": "Boötes",
    "Cae": "Caelum",
    "Cam": "Camelopardalis",
    "Cnc": "Cancer",
    "CVn": "Canes Venatici",
    "CMa": "Canis Major",
    "CMi": "Canis Minor",
    "Cap": "Capricornus",
    "Car": "Carina",
    "Cas": "Cassiopeia",
    "Cen": "Centaurus",
    "Cep": "Cepheus",
    "Cet": "Cetus",
    "Cha": "Chamaeleon",
    "Cir": "Circinus",
    "Col": "Columba",
    "Com": "Coma Berenices",
    "CrA": "Corona Australis",
    "CrB": "Corona Borealis",
    "Crv": "Corvus",
    "Crt": "Crater",
    "Cru": "Crux",
    "Cyg": "Cygnus",
    "Del": "Delphinus",
    "Dor": "Dorado",
    "Dra": "Draco",
    "Equ": "Equuleus",
    "Eri": "Eridanus",
    "For": "Fornax",
    "Gem": "Gemini",
    "Gru": "Grus",
    "Her": "Hercules",
    "Hor": "Horologium",
    "Hya": "Hydra",
    "Hyi": "Hydrus",
    "Ind": "Indus",
    "Lac": "Lacerta",
    "Leo": "Leo",
    "LMi": "Leo Minor",
    "Lep": "Lepus",
    "Lib": "Libra",
    "Lup": "Lupus",
    "Lyn": "Lynx",
    "Lyr": "Lyra",
    "Men": "Mensa",
    "Mic": "Microscopium",
    "Mon": "Monoceros",
    "Mus": "Musca",
    "Nor": "Norma",
    "Oct": "Octans",
    "Oph": "Ophiuchus",
    "Ori": "Orion",
    "Pav": "Pavo",
    "Peg": "Pegasus",
    "Per": "Perseus",
    "Phe": "Phoenix",
    "Pic": "Pictor",
    "Psc": "Pisces",
    "PsA": "Piscis Austrinus",
    "Pup": "Puppis",
    "Pyx": "Pyxis",
    "Ret": "Reticulum",
    "Sge": "Sagitta",
    "Sgr": "Sagittarius",
    "Sco": "Scorpius",
    "Scl": "Sculptor",
    "Sct": "Scutum",
    "Ser": "Serpens",
    "Sex": "Sextans",
    "Tau": "Taurus",
    "Tel": "Telescopium",
    "Tri": "Triangulum",
    "TrA": "Triangulum Australe",
    "Tuc": "Tucana",
    "UMa": "Ursa Major",
    "UMi": "Ursa Minor",
    "Vel": "Vela",
    "Vir": "Virgo",
    "Vol": "Volans",
    "Vul": "Vulpecula",
}


# ---------------------------------------------------------------------------
# Stars
# ---------------------------------------------------------------------------

def load_star_ids() -> Set[int]:
    """
    Load the HR identifiers that actually exist in stars.json.

    This lets us detect broken constellation references during
    the build instead of discovering them at runtime.
    """

    if not STARS_FILE.exists():
        print(
            f"Error: stars catalog not found: {STARS_FILE}",
            file=sys.stderr,
        )
        sys.exit(1)

    with STARS_FILE.open(
        "r",
        encoding="utf-8",
    ) as file:
        stars = json.load(file)

    return {
        int(star["id"])
        for star in stars
        if "id" in star
    }


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def parse_line(line: str) -> tuple[str, List[List[int]]] | None:
    """
    Parse a constellation line.

    Example:

        Cnc = [74739, 74198, 74442];[69267, 74442]

    Each bracketed sequence represents a continuous line.
    """

    line = line.strip()

    if not line:
        return None

    if line.startswith("#"):
        return None

    match = re.match(
        r"^([A-Za-z]{3})\s*=\s*(.+)$",
        line,
    )

    if not match:
        return None

    abbreviation = match.group(1)
    line_data = match.group(2)

    segments: List[List[int]] = []

    for segment in re.findall(
        r"\[([^\]]+)\]",
        line_data,
    ):
        stars = []

        for value in segment.split(","):
            value = value.strip()

            if not value:
                continue

            try:
                stars.append(int(value))
            except ValueError:
                print(
                    f"Warning: invalid star ID "
                    f"'{value}' in {abbreviation}",
                    file=sys.stderr,
                )

        if len(stars) >= 2:
            segments.append(stars)

    if not segments:
        return None

    return abbreviation, segments


def parse_constellations(
    star_ids: Set[int],
) -> Dict[str, Dict]:
    """
    Parse all constellation definitions.

    Missing HR identifiers are reported but do not crash
    the entire generation process.
    """

    if not SOURCE_FILE.exists():
        print(
            f"Error: constellation source not found:\n"
            f"{SOURCE_FILE}",
            file=sys.stderr,
        )
        sys.exit(1)

    constellations: Dict[str, Dict] = {}

    missing_stars: Dict[str, Set[int]] = {}

    with SOURCE_FILE.open(
        "r",
        encoding="utf-8",
    ) as file:
        for line_number, line in enumerate(
            file,
            start=1,
        ):
            parsed = parse_line(line)

            if parsed is None:
                continue

            abbreviation, segments = parsed

            valid_segments: List[List[int]] = []

            for segment in segments:
                valid_segment = []

                for star_id in segment:
                    if star_id not in star_ids:
                        missing_stars.setdefault(
                            abbreviation,
                            set(),
                        ).add(star_id)
                        continue

                    valid_segment.append(star_id)

                if len(valid_segment) >= 2:
                    valid_segments.append(
                        valid_segment
                    )

            if not valid_segments:
                continue

            if abbreviation not in constellations:
                constellations[abbreviation] = {
                    "id": abbreviation,
                    "name": CONSTELLATION_NAMES.get(
                        abbreviation,
                        abbreviation,
                    ),
                    "lines": [],
                }

            constellations[
                abbreviation
            ]["lines"].extend(valid_segments)

    if missing_stars:
        print(
            "\nWarning: some constellation stars "
            "were not found in stars.json:",
            file=sys.stderr,
        )

        for abbreviation, ids in sorted(
            missing_stars.items()
        ):
            print(
                f"  {abbreviation}: "
                f"{sorted(ids)}",
                file=sys.stderr,
            )

    return constellations


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def write_output(
    constellations: Dict[str, Dict],
) -> None:
    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    data = sorted(
        constellations.values(),
        key=lambda item: item["name"],
    )

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            data,
            file,
            indent=2,
            ensure_ascii=False,
        )

        file.write("\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("Loading star catalog...")

    star_ids = load_star_ids()

    print(
        f"Loaded {len(star_ids)} star identifiers."
    )

    print("Parsing constellation data...")

    constellations = parse_constellations(
        star_ids
    )

    print(
        f"Parsed {len(constellations)} constellations."
    )

    total_lines = sum(
        len(constellation["lines"])
        for constellation in constellations.values()
    )

    print(
        f"Parsed {total_lines} constellation lines."
    )

    print(
        f"Writing catalog to: {OUTPUT_FILE}"
    )

    write_output(constellations)

    print("Done.")


if __name__ == "__main__":
    main()