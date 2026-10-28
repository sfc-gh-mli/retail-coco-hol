-- ============================================================================
-- Retail Cortex Code Lab: Snowflake admin setup (run BEFORE the lab)
-- Synthetic data only. Run ONE section at a time with an admin-approved role.
-- Stop on any error. Do not rerun completed sections; names deliberately fail
-- on collision instead of replacing existing objects.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- SECTION 1: Preflight (read only). Confirm this is the intended account.
-- ---------------------------------------------------------------------------
SELECT CURRENT_ORGANIZATION_NAME() AS ORGANIZATION,
       CURRENT_ACCOUNT_NAME() AS ACCOUNT_NAME,
       CURRENT_USER() AS USER_NAME,
       CURRENT_ROLE() AS ROLE_NAME;
-- Proposed new objects: database HOL_EXAMPLE_20261026, warehouse HOL_EXAMPLE_WH, role HOL_EXAMPLE_P001.
-- STOP: confirm the account and that these names are unused.

-- ---------------------------------------------------------------------------
-- SECTION 2: Create the sandbox database, warehouse, stage and tables.
-- ---------------------------------------------------------------------------
CREATE DATABASE HOL_EXAMPLE_20261026 COMMENT = 'Synthetic Cortex Code hands-on lab sandbox';
CREATE SCHEMA HOL_EXAMPLE_20261026.SOURCE;
CREATE WAREHOUSE HOL_EXAMPLE_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
CREATE FILE FORMAT HOL_EXAMPLE_20261026.SOURCE.HOL_CSV
  TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;
CREATE STAGE HOL_EXAMPLE_20261026.SOURCE.HOL_DATA
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') FILE_FORMAT = HOL_EXAMPLE_20261026.SOURCE.HOL_CSV;
CREATE TABLE HOL_EXAMPLE_20261026.SOURCE.LOCATIONS (LOCATION_ID NUMBER NOT NULL, LOCATION_NAME VARCHAR NOT NULL);
CREATE TABLE HOL_EXAMPLE_20261026.SOURCE.CUSTOMERS (CUSTOMER_ID NUMBER NOT NULL, SEGMENT VARCHAR NOT NULL, LOCATION_ID NUMBER NOT NULL);
CREATE TABLE HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS (
  TRANSACTION_ID NUMBER NOT NULL, CUSTOMER_ID NUMBER NOT NULL, TRANSACTION_TIME TIMESTAMP_NTZ NOT NULL,
  AMOUNT NUMBER(12,2) NOT NULL, PRODUCT_CATEGORY VARCHAR NOT NULL, CHANNEL VARCHAR NOT NULL, STATUS VARCHAR NOT NULL);

-- ---------------------------------------------------------------------------
-- SECTION 3: Upload data (Snowsight UI, no SQL).
-- Unzip data/retail-coco-hol-data.zip from the lab repo. In Snowsight open
-- HOL_EXAMPLE_20261026.SOURCE.HOL_DATA and upload locations.csv, customers.csv, transactions.csv.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- SECTION 4: Load and reconcile. Expected values are in the lab README.
-- ---------------------------------------------------------------------------
USE WAREHOUSE HOL_EXAMPLE_WH;
COPY INTO HOL_EXAMPLE_20261026.SOURCE.LOCATIONS (LOCATION_ID, LOCATION_NAME)
  FROM @HOL_EXAMPLE_20261026.SOURCE.HOL_DATA FILES = ('locations.csv')
  FILE_FORMAT = (FORMAT_NAME = 'HOL_EXAMPLE_20261026.SOURCE.HOL_CSV') ON_ERROR = 'ABORT_STATEMENT';
COPY INTO HOL_EXAMPLE_20261026.SOURCE.CUSTOMERS (CUSTOMER_ID, SEGMENT, LOCATION_ID)
  FROM @HOL_EXAMPLE_20261026.SOURCE.HOL_DATA FILES = ('customers.csv')
  FILE_FORMAT = (FORMAT_NAME = 'HOL_EXAMPLE_20261026.SOURCE.HOL_CSV') ON_ERROR = 'ABORT_STATEMENT';
COPY INTO HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS
  (TRANSACTION_ID, CUSTOMER_ID, TRANSACTION_TIME, AMOUNT, PRODUCT_CATEGORY, CHANNEL, STATUS)
  FROM @HOL_EXAMPLE_20261026.SOURCE.HOL_DATA FILES = ('transactions.csv')
  FILE_FORMAT = (FORMAT_NAME = 'HOL_EXAMPLE_20261026.SOURCE.HOL_CSV') ON_ERROR = 'ABORT_STATEMENT';
SELECT 'LOCATIONS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM HOL_EXAMPLE_20261026.SOURCE.LOCATIONS
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM HOL_EXAMPLE_20261026.SOURCE.CUSTOMERS
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS;
SELECT SUM(IFF(STATUS = 'COMPLETED', AMOUNT, 0)) AS NET_SPEND FROM HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS;

-- ---------------------------------------------------------------------------
-- SECTION 5: Participant role and writable schema.
-- Repeat this section once per participant with a new schema/role pair
-- (P002 / HOL_EXAMPLE_P002, ...). One shared role is NOT isolation.
-- ---------------------------------------------------------------------------
CREATE ROLE HOL_EXAMPLE_P001;
CREATE SCHEMA HOL_EXAMPLE_20261026.P001;
GRANT USAGE ON DATABASE HOL_EXAMPLE_20261026 TO ROLE HOL_EXAMPLE_P001;
GRANT USAGE ON SCHEMA HOL_EXAMPLE_20261026.SOURCE TO ROLE HOL_EXAMPLE_P001;
GRANT USAGE ON SCHEMA HOL_EXAMPLE_20261026.P001 TO ROLE HOL_EXAMPLE_P001;
GRANT USAGE ON WAREHOUSE HOL_EXAMPLE_WH TO ROLE HOL_EXAMPLE_P001;
GRANT SELECT ON TABLE HOL_EXAMPLE_20261026.SOURCE.LOCATIONS TO ROLE HOL_EXAMPLE_P001;
GRANT SELECT ON TABLE HOL_EXAMPLE_20261026.SOURCE.CUSTOMERS TO ROLE HOL_EXAMPLE_P001;
GRANT SELECT ON TABLE HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS TO ROLE HOL_EXAMPLE_P001;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA HOL_EXAMPLE_20261026.P001 TO ROLE HOL_EXAMPLE_P001;
-- Assign to an existing user (keep the roster private, not in this repo):
-- GRANT ROLE HOL_EXAMPLE_P001 TO USER <participant_user>;

-- ---------------------------------------------------------------------------
-- SECTION 6: Cortex Code access and track-specific grants. Admin review required.
-- ---------------------------------------------------------------------------
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE HOL_EXAMPLE_P001;
-- Confirm model access with the account's CoCo Admin SQL preview.
-- Snowsight may additionally need (only if your account still requires it):
-- GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE HOL_EXAMPLE_P001;
-- Do not change cross-region inference or enable all models without admin policy approval.
-- Data Engineering: base table/view creation above is sufficient.

-- ---------------------------------------------------------------------------
-- SECTION 7: Verify AS THE PARTICIPANT (not as admin).
-- ---------------------------------------------------------------------------
USE ROLE HOL_EXAMPLE_P001;
USE SECONDARY ROLES NONE;
USE WAREHOUSE HOL_EXAMPLE_WH;
USE SCHEMA HOL_EXAMPLE_20261026.P001;
SELECT COUNT(*) AS SOURCE_ROWS FROM HOL_EXAMPLE_20261026.SOURCE.TRANSACTIONS;
CREATE TEMPORARY TABLE HOL_EXAMPLE_20261026.P001.HOL_WRITE_PROBE (ID NUMBER);
INSERT INTO HOL_EXAMPLE_20261026.P001.HOL_WRITE_PROBE VALUES (1);
SELECT COUNT(*) AS EXPECTED_ONE FROM HOL_EXAMPLE_20261026.P001.HOL_WRITE_PROBE;
DROP TABLE HOL_EXAMPLE_20261026.P001.HOL_WRITE_PROBE;
-- Then run the track smoke test listed in the lab app's Admin setup page.

-- ---------------------------------------------------------------------------
-- SECTION 8: Cleanup AFTER the event. DISABLED. Review inventory and retention,
-- stop any schedules/monitors first, then uncomment only approved lines.
-- ---------------------------------------------------------------------------
-- DROP DATABASE HOL_EXAMPLE_20261026;
-- DROP WAREHOUSE HOL_EXAMPLE_WH;
-- DROP ROLE HOL_EXAMPLE_P001;
-- Never drop customer users.
