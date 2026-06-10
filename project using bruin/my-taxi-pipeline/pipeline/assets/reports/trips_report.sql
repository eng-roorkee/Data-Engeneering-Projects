/* @bruin

name: reports.trips_report

type: duckdb.sql

depends:
  - staging.trips

materialization:
  type: table
  strategy: create+replace

columns:
  - name: pickup_date
    type: date
    description: Trip pickup date
    primary_key: true
    checks:
      - name: not_null
  - name: taxi_vendor
    type: string
    description: Taxi vendor (1 or 2)
    primary_key: true
  - name: payment_type_name
    type: string
    description: Payment type name
    primary_key: true
  - name: trip_count
    type: bigint
    description: Number of trips in this group
    checks:
      - name: positive
  - name: total_distance_miles
    type: float
    description: Total trip distance in miles
  - name: total_fare_amount
    type: float
    description: Total fare amount in USD
  - name: avg_fare_amount
    type: float
    description: Average fare amount per trip
  - name: total_tip_amount
    type: float
    description: Total tip amount in USD
  - name: avg_tip_amount
    type: float
    description: Average tip per trip
  - name: total_amount
    type: float
    description: Total amount including all charges
  - name: avg_passenger_count
    type: float
    description: Average passengers per trip


@bruin */

SELECT
  DATE(st.tpep_pickup_datetime) as pickup_date,
  CAST(st.vendor_id AS VARCHAR) as taxi_vendor,
  st.payment_type_name,
  COUNT(*) as trip_count,
  SUM(st.trip_distance) as total_distance_miles,
  SUM(st.fare_amount) as total_fare_amount,
  AVG(st.fare_amount) as avg_fare_amount,
  SUM(st.tip_amount) as total_tip_amount,
  AVG(st.tip_amount) as avg_tip_amount,
  SUM(st.total_amount) as total_amount,
  AVG(st.passenger_count) as avg_passenger_count
FROM staging.trips st
WHERE DATE(st.tpep_pickup_datetime) >= '{{ start_date }}'
  AND DATE(st.tpep_pickup_datetime) < '{{ end_date }}'
GROUP BY
  DATE(st.tpep_pickup_datetime),
  st.vendor_id,
  st.payment_type_name
ORDER BY
  pickup_date DESC,
  trip_count DESC
