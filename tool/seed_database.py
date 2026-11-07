#!/usr/bin/env python3
"""
WorkAxis Database Seeding Tool
Connects to Cloud SQL PostgreSQL instance and seeds initial data.
"""

import sys
import os
import pg8000.native

HOST = os.getenv("PGHOST", "127.0.0.1")
PORT = int(os.getenv("PGPORT", "5433"))
DATABASE = os.getenv("PGDATABASE", "workaxis")
USER = os.getenv("PGUSER")
PASSWORD = os.getenv("PGPASSWORD", "")

SQL_FILE = os.path.join(os.path.dirname(__file__), "..", "dataconnect", "seed_data.sql")


def seed_database():
    if not USER:
        print("Error: PGUSER environment variable is not set.")
        print("Set it to the Cloud SQL IAM database user, e.g.:")
        print("  $env:PGUSER = '<your-iam-user>'   (PowerShell)")
        sys.exit(2)

    print(f"Connecting to PostgreSQL database '{DATABASE}' at {HOST}:{PORT} as '{USER}'...")
    try:
        conn = pg8000.native.Connection(
            user=USER,
            host=HOST,
            port=PORT,
            database=DATABASE,
            password=PASSWORD,
        )
    except Exception as e:
        print(f"Error connecting to database: {e}")
        print("\nMake sure cloud-sql-proxy is running:")
        print("  cloud-sql-proxy --auto-iam-authn omniretail-60c71:asia-south1:omniretail-sql --port 5433")
        sys.exit(1)

    print("Connected successfully!")
    print(f"Reading SQL script from: {SQL_FILE}")

    with open(SQL_FILE, "r", encoding="utf-8") as f:
        sql_content = f.read()

    print("Executing seed SQL script...")
    conn.run(sql_content)
    print("Seed SQL executed successfully!\n")

    # Verify counts
    tables = [
        "organization",
        "commercial_agreement",
        "license_event",
        "branch",
        "organization_member",
        "user_branch_assignment",
        "return_record",
    ]

    print("==================================================")
    print("WorkAxis Database Seed Verification")
    print("==================================================")
    for table in tables:
        count = conn.run(f"SELECT count(*) FROM {table};")[0][0]
        print(f"  {table:25}: {count:4} records")

    print("==================================================")
    print("Sample Organizations Seeded:")
    orgs = conn.run("SELECT id, name, code, status, category, country FROM organization;")
    for o in orgs:
        print(f"  - [{o[2]}] {o[1]} ({o[0]}) | Status: {o[3]} | Category: {o[4]} | Country: {o[5]}")

    print("\nSample Branches Seeded:")
    branches = conn.run("SELECT code, name, is_main_branch, geofence_radius_meters, location FROM branch;")
    for b in branches:
        main_tag = "[MAIN]" if b[2] else "      "
        print(f"  - {main_tag} [{b[0]}] {b[1]} | Geofence: {b[3]}m | Location: {b[4]}")

    print("\nSample Members Seeded:")
    members = conn.run("SELECT username, full_name, role, email, phone FROM organization_member;")
    for m in members:
        print(f"  - @{m[0]:15} | {m[1]:15} | Role: {m[2]:15} | {m[3]}")

    print("\nDatabase seeding completed successfully.")
    conn.close()


if __name__ == "__main__":
    seed_database()
