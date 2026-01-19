import sqlite3
import pandas as pd
from pathlib import Path

print("--- Start Conn Test ---")

db_path = Path(__file__).parent.parent / "tempo_dev.db"
conn = sqlite3.connect(db_path)

samples = pd.read_sql("SELECT * FROM health_samples", conn)

print(f"Samples: {len(samples)}")

# Date range
min = samples['start_date'].min()
max = samples['end_date'].max()
print(f"Date range: {min} to {max}")
print(f"Days covered: {(pd.to_datetime(max) - pd.to_datetime(min)).days}\n")

# Type breakdown
print("Sample types:")
print(samples['type'].value_counts())
print()
