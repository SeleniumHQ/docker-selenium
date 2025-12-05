import argparse
import re
import sys
from pathlib import Path

BASE_VERSION_PATTERN = re.compile(r"^BASE_VERSION\s*:=.*?(\d+\.\d+\.\d+)", re.MULTILINE)
BASE_VERSION_NIGHTLY_PATTERN = re.compile(
    r"^BASE_VERSION_NIGHTLY\s*:=.*?(\d+\.\d+\.\d+-SNAPSHOT)",
    re.MULTILINE,
)


def find_makefile():
    cwd = Path.cwd()
    candidate = cwd / "Makefile"
    if candidate.exists():
        return candidate

    script_dir = Path(__file__).parent
    if script_dir != cwd:
        candidate = script_dir / "Makefile"
        if candidate.exists():
            return candidate

    return None


def parse_versions(content: str):
    base_match = BASE_VERSION_PATTERN.search(content)
    nightly_match = BASE_VERSION_NIGHTLY_PATTERN.search(content)

    if not base_match:
        raise ValueError("BASE_VERSION not found in Makefile")
    if not nightly_match:
        raise ValueError("BASE_VERSION_NIGHTLY not found in Makefile")

    return base_match.group(1), nightly_match.group(1)


def bump_minor(version: str) -> str:
    parts = version.split(".")
    if len(parts) != 3:
        raise ValueError(f"Unsupported version format: {version}")

    major, minor, _ = parts

    try:
        minor_number = int(minor)
    except ValueError as exc:
        raise ValueError(f"Minor version is not an integer in '{version}'") from exc

    return f"{major}.{minor_number + 1}.0"


def update_versions(makefile_path: Path, expected_base_version: str | None) -> bool:
    content = makefile_path.read_text()
    current_base, current_nightly = parse_versions(content)

    if expected_base_version and current_base == expected_base_version:
        print(
            "BASE_VERSION already matches expected value "
            f"({expected_base_version}); skipping updates."
        )
        return False

    nightly_base = current_nightly.removesuffix("-SNAPSHOT")
    new_base = nightly_base
    new_nightly = bump_minor(nightly_base) + "-SNAPSHOT"

    if new_base == current_base and new_nightly == current_nightly:
        print("Makefile already uses the desired versions; nothing to update.")
        return False

    updated_content = content.replace(current_base, new_base)
    updated_content = updated_content.replace(current_nightly, new_nightly)

    makefile_path.write_text(updated_content)

    print(f"Updated BASE_VERSION from {current_base} to {new_base}")
    print(f"Updated BASE_VERSION_NIGHTLY from {current_nightly} to {new_nightly}")
    return True


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Bump Selenium Grid versions in Makefile")
    parser.add_argument(
        "makefile",
        nargs="?",
        help="Optional path to the Makefile (default: search in CWD then script directory)",
    )
    parser.add_argument(
        "--expected-base-version",
        dest="expected_base_version",
        help="If provided and Makefile already contains this BASE_VERSION, skip updating.",
    )
    args = parser.parse_args(argv)

    if args.makefile:
        makefile_path = Path(args.makefile)
    else:
        found = find_makefile()
        if not found:
            print("Error: Could not locate Makefile", file=sys.stderr)
            return 1
        makefile_path = found

    if not makefile_path.exists():
        print(f"Error: {makefile_path} does not exist", file=sys.stderr)
        return 1

    try:
        changed = update_versions(makefile_path, args.expected_base_version)
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    return 0 if changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
