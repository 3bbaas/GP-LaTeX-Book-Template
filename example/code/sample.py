"""
Sample Python Module -- Demonstrates code snippet import in LaTeX.
"""

def main():
    """Main entry point for the application."""
    data = load_data("input.csv")
    results = process(data)
    export(results, "output.json")
    print(f"Processed {len(results)} records successfully.")


def load_data(filepath: str) -> list[dict]:
    """Load data from a CSV file and return as list of dicts."""
    import csv
    with open(filepath, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


def process(data: list[dict]) -> list[dict]:
    """Apply transformations to each record."""
    processed = []
    for record in data:
        transformed = {
            key: value.strip().lower()
            for key, value in record.items()
        }
        processed.append(transformed)
    return processed


def export(data: list[dict], filepath: str) -> None:
    """Export processed data to a JSON file."""
    import json
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
