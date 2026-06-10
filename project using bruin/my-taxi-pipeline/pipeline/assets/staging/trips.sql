/* @bruin

name: staging.trips
type: duckdb.sql

depends:
  - ingestion.trips
  - ingestion.payment_lookup

materialization:
  type: table
  strategy: create+replace

@bruin */

WITH raw_trips AS (
  SELECT
    VENDOR_ID as vendor_id,
    TPEP_PICKUP_DATETIME as tpep_pickup_datetime,
    TPEP_DROPOFF_DATETIME as tpep_dropoff_datetime,
    PASSENGER_COUNT as passenger_count,
    TRIP_DISTANCE as trip_distance,
    RATECODE_ID as ratecodeid,
    STORE_AND_FWD_FLAG as store_and_fwd_flag,
    PU_LOCATION_ID as pu_location_id,
    DO_LOCATION_ID as do_location_id,
    PAYMENT_TYPE as payment_type,
    FARE_AMOUNT as fare_amount,
    EXTRA as extra,
    MTA_TAX as mta_tax,
    TIP_AMOUNT as tip_amount,
    TOLLS_AMOUNT as tolls_amount,
    TOTAL_AMOUNT as total_amount,
    CONGESTION_SURCHARGE as congestion_surcharge,
    AIRPORT_FEE as airport_fee,
    EXTRACTED_AT as extracted_at,
    ROW_NUMBER() OVER (
      PARTITION BY TPEP_PICKUP_DATETIME, PU_LOCATION_ID, DO_LOCATION_ID, VENDOR_ID, PASSENGER_COUNT
      ORDER BY EXTRACTED_AT DESC
    ) as rn
  FROM ingestion.trips
  WHERE TPEP_PICKUP_DATETIME IS NOT NULL
    AND TPEP_DROPOFF_DATETIME IS NOT NULL
    AND PU_LOCATION_ID IS NOT NULL
    AND DO_LOCATION_ID IS NOT NULL
    AND PAYMENT_TYPE IS NOT NULL
)
SELECT
  rt.vendor_id,
  rt.tpep_pickup_datetime,
  rt.tpep_dropoff_datetime,
  rt.passenger_count,
  rt.trip_distance,
  rt.ratecodeid,
  rt.store_and_fwd_flag,
  rt.pu_location_id,
  rt.do_location_id,
  rt.payment_type,
  rt.fare_amount,
  rt.extra,
  rt.mta_tax,
  rt.tip_amount,
  rt.tolls_amount,
  rt.total_amount,
  rt.congestion_surcharge,
  rt.airport_fee,
  COALESCE(pl.payment_type_name, 'unknown') as payment_type_name
FROM raw_trips rt
LEFT JOIN ingestion.payment_lookup pl ON rt.payment_type = pl.payment_type_id
WHERE rt.rn = 1
