#!/usr/bin/env python3
"""
codediff.py — Generate a unified diff file from two source files.

The output .diff file can be included in LaTeX via:
    \\inputminted{diff}{code/my-change.diff}

Usage:
    python3 scripts/codediff.py <file_a> <file_b> -o <output.diff>
    python3 scripts/codediff.py <file_a> <file_b>            # prints to stdout

Examples:
    python3 scripts/codediff.py src/code/old.py src/code/new.py -o src/code/refactor.diff
    python3 scripts/codediff.py src/code/sync.py src/code/async.py -o src/code/sync-vs-async.diff
"""

import argparse
import difflib
import sys
from pathlib import Path


def generate_diff(file_a: str, file_b: str, label_a: str | None = None, label_b: str | None = None) -> str:
    """Generate a unified diff between two files."""
    path_a = Path(file_a)
    path_b = Path(file_b)

    if not path_a.exists():
        print(f"Error: {file_a} not found", file=sys.stderr)
        sys.exit(1)
    if not path_b.exists():
        print(f"Error: {file_b} not found", file=sys.stderr)
        sys.exit(1)

    lines_a = path_a.read_text().splitlines(keepends=True)
    lines_b = path_b.read_text().splitlines(keepends=True)

    label_a = label_a or path_a.name
    label_b = label_b or path_b.name

    diff = difflib.unified_diff(
        lines_a, lines_b,
        fromfile=label_a,
        tofile=label_b,
        lineterm=""
    )

    return "\n".join(line.rstrip() for line in diff)


def main():
    parser = argparse.ArgumentParser(
        description="Generate a unified diff file for LaTeX minted inclusion"
    )
    parser.add_argument("file_a", help="Original file (before)")
    parser.add_argument("file_b", help="Modified file (after)")
    parser.add_argument("-o", "--output", help="Output .diff file (default: stdout)")
    parser.add_argument("--label-a", help="Label for file A (default: filename)")
    parser.add_argument("--label-b", help="Label for file B (default: filename)")

    args = parser.parse_args()

    diff_text = generate_diff(args.file_a, args.file_b, args.label_a, args.label_b)

    if not diff_text:
        print("Files are identical — no diff generated.", file=sys.stderr)
        sys.exit(0)

    if args.output:
        Path(args.output).write_text(diff_text + "\n")
        print(f"[DONE] Generated: {args.output}")
    else:
        print(diff_text)


if __name__ == "__main__":
    main()
