"""@bruin

name: ingestion.trips

type: python

image: python:3.11

connection: duckdb-default

materialization:
  type: table
  strategy: append

columns:
  - name: vendor_id
    type: integer
    description: Vendor ID (1=Creative Mobile Technologies, 2=VeriFone Inc)
  - name: tpep_pickup_datetime
    type: timestamp
    description: Trip start time
  - name: tpep_dropoff_datetime
    type: timestamp
    description: Trip end time
  - name: passenger_count
    type: integer
    description: Number of passengers
  - name: trip_distance
    type: float
    description: Trip distance in miles
  - name: ratecodeid
    type: integer
    description: Rate code ID
  - name: store_and_fwd_flag
    type: string
    description: Store and forward flag
  - name: pu_location_id
    type: integer
    description: Pickup location ID
  - name: do_location_id
    type: integer
    description: Dropoff location ID
  - name: payment_type
    type: integer
    description: Payment type ID
    primary_key: true
  - name: fare_amount
    type: float
    description: Fare amount
  - name: extra
    type: float
    description: Extra charges
  - name: mta_tax
    type: float
    description: MTA tax
  - name: tip_amount
    type: float
    description: Tip amount
  - name: tolls_amount
    type: float
    description: Tolls amount
  - name: total_amount
    type: float
    description: Total amount
  - name: congestion_surcharge
    type: float
    description: Congestion surcharge
  - name: airport_fee
    type: float
    description: Airport fee
  - name: extracted_at
    type: timestamp
    description: Extraction timestamp

@bruin"""

import os
import json
from datetime import datetime, timedelta
import pandas as pd
import requests
from dateutil.relativedelta import relativedelta


def materialize():
    """
    Fetch NYC taxi trip data from TLC public endpoint.
    
    - Supports multiple taxi types (yellow, green, etc.)
    - Uses Bruin date window for incremental ingestion
    - Returns raw data without cleaning (deduplication handled in staging)
    """
    # Get Bruin runtime variables
    start_date_str = os.getenv("BRUIN_START_DATE", "2022-01-01")
    end_date_str = os.getenv("BRUIN_END_DATE", "2022-01-31")
    bruin_vars = json.loads(os.getenv("BRUIN_VARS", "{}"))
    
    taxi_types = bruin_vars.get("taxi_types", ["yellow", "green"])
    
    # Parse dates
    start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
    end_date = datetime.strptime(end_date_str, "%Y-%m-%d")
    
    # Base URL for NYC TLC data
    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data"
    
    dfs = []
    current_date = start_date
    
    while current_date <= end_date:
        year = current_date.year
        month = current_date.month
        month_str = f"{month:02d}"
        
        for taxi_type in taxi_types:
            filename = f"{taxi_type}_tripdata_{year}-{month_str}.parquet"
            url = f"{base_url}/{filename}"
            
            try:
                print(f"Fetching: {url}")
                response = requests.head(url, timeout=5)
                
                if response.status_code == 200:
                    # File exists, read it
                    df = pd.read_parquet(url)
                    
                    # Standardize column names if needed
                    if taxi_type == "yellow":
                        df = df.rename(columns={
                            "tpep_pickup_datetime": "tpep_pickup_datetime",
                            "tpep_dropoff_datetime": "tpep_dropoff_datetime"
                        })
                    elif taxi_type == "green":
                        df = df.rename(columns={
                            "lpep_pickup_datetime": "tpep_pickup_datetime",
                            "lpep_dropoff_datetime": "tpep_dropoff_datetime"
                        })
                    
                    # Add extracted_at timestamp
                    df["extracted_at"] = pd.Timestamp.now()
                    
                    dfs.append(df)
                    print(f"  ✓ Loaded {len(df)} rows")
                else:
                    print(f"  ✗ Not found (HTTP {response.status_code})")
                    
            except Exception as e:
                print(f"  ✗ Error: {str(e)}")
        
        # Move to next month
        current_date += relativedelta(months=1)
    
    # Combine all dataframes
    if dfs:
        final_df = pd.concat(dfs, ignore_index=True)
        print(f"\nTotal rows fetched: {len(final_df)}")
        return final_df
    else:
        print("No data fetched!")
        return pd.DataFrame()


