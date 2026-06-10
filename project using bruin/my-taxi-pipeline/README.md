# Overview - End-to-End Data Platform

This hands-on tutorial guides you through building a **complete NYC Taxi data pipeline** from scratch using Bruin - a unified CLI tool for data ingestion, transformation, orchestration, and governance.


## Learning Goals

You'll learn to build a production-ready ELT pipeline that:
- **Ingests** real NYC taxi trip data from public APIs using Python
- **Transforms** and cleans raw data with SQL, applying incremental strategies and deduplication
- **Reports** aggregated analytics with built-in quality checks
- **Deploys** to cloud infrastructure (BigQuery)

This is a learn-by-doing experience with AI assistance available through Bruin MCP. Follow the comprehensive step-by-step tutorial section below.

## Tutorial Outline

- **Part 1**: What is a Data Platform? - Learn about modern data stack components and where Bruin fits in
- **Part 2**: Setting Up Your First Bruin Project - Install Bruin, initialize a project, and configure environments
- **Part 3**: End-to-End NYC Taxi ELT Pipeline - Build ingestion, staging, and reporting layers with real data
- **Part 4**: Data Engineering with AI Agent - Use Bruin MCP to build pipelines with AI assistance
- **Part 5**: Deploy to Cloud - Deploy to BigQuery and run pipelines on Bruin Cloud

## Pipeline Skeleton

The suggested structure separates ingestion, staging, and reporting, but you may structure your pipeline however you like.

The required parts of a Bruin project are:
- `.bruin.yml` in the root directory
- `pipeline.yml` in the `pipeline/` directory (or in the root directory if you keep everything flat)
- `assets/` folder next to `pipeline.yml` containing your Python, SQL, and YAML asset files

```text
zoomcamp/
├── .bruin.yml                              # Environments + connections (local DuckDB, BigQuery, etc.)
├── README.md                               # Learning goals, workflow, best practices
└── pipeline/
    ├── pipeline.yml                        # Pipeline name, schedule, variables
    └── assets/
        ├── ingestion/
        │   ├── trips.py                    # Python ingestion
        │   ├── requirements.txt            # Python dependencies for ingestion
        │   ├── payment_lookup.asset.yml    # Seed asset definition
        │   └── payment_lookup.csv          # Seed data
        ├── staging/
        │   └── trips.sql                   # Clean and transform
        └── reports/
            └── trips_report.sql            # Aggregation for analytics
```



> **Prerequisites**: Familiarity with SQL, basic Python, and command-line tools. Prior exposure to orchestration and transformation concepts is helpful but not required.

---

## Part 1: What is a Data Platform?

### Learning Goals
- Understand what a data platform is and why you need one
- Learn how Bruin fits into the modern data stack
- Grasp Bruin's core abstractions: assets, pipelines, environments, connections

### 1.1 The Modern Data Stack Components
- **Data extraction/ingestion**: Moving data from sources to your warehouse
- **Data transformation**: Cleaning, modeling, and aggregating data (the "T" in ELT)
- **Data orchestration**: Scheduling and managing pipeline runs
- **Data quality/governance**: Ensuring data accuracy and consistency
- **Metadata management**: Tracking lineage, ownership, and documentation

### 1.2 Where Bruin Fits In
- Bruin = ingestion + transformation + quality + orchestration in one tool
- Handles pipeline orchestration similar to Airflow (dependency resolution, scheduling, retries)
- "What if Airbyte, Airflow, dbt, and Great Expectations had a lovechild"
- Runs locally, on VMs, or in CI/CD with no vendor lock-in
- Apache-licensed open source

### 1.3 Bruin Design Principles (Key Takeaways)
- Everything is version-controllable text (no UI/database configs)
- Real pipelines use multiple technologies (SQL + Python + R)
- Mix-and-match sources and destinations in a single pipeline
- Data quality is a first-class citizen, not an afterthought
- Quick feedback cycle: fast CLI, local development

### 1.4 Core Concepts
- **Asset**: Any data artifact that carries value (table, view, file, ML model, etc.)
- **Pipeline**: A group of assets executed together in dependency order
- **Environment**: A named set of connection configs (e.g., `default`, `production`) so the same pipeline can run locally and in production
- **Connection**: Credentials to authenticate with external data sources & destinations
- **Pipeline run**: A single execution instance with specific dates and configuration

---


### Learning Goals
- Install Bruin CLI
- Initialize a project from a template
- Understand the project file structure
- Configure environments and connections

### 2.1 Installation


**Step 1: Install Bruin CLI**

```bash
curl -LsSf https://getbruin.com/install/cli | sh
```

Verify installation: `bruin version`

If your terminal prints `To use the installed binaries, please restart the shell`, do one of the following:
- **Restart your terminal** (close + reopen) - simplest and most reliable
- **Reload your shell**:
  - `exec $SHELL -l` (works for most shells)
  - zsh: `source ~/.zshrc`
  - bash: `source ~/.bashrc` (or `source ~/.bash_profile` on some macOS setups)
  - fish: `exec fish`

**Step 2: Install IDE Extension (VS Code, Cursor, etc.)**

- Open VS Code or Cursor → Extensions
- Search: "Bruin" (publisher: bruin)
- Install, then reload VS Code


### 2.2 Your First Pipeline with the Default Template

Let's start by initializing a simple project to learn the basics before diving into the full NYC Taxi pipeline.

**Initialize the default template:**
```bash
bruin init default my-first-pipeline
cd bruin
```

**Explore the generated structure:**
```text
my-first-pipeline/
├── .bruin.yml              # Environment and connection configuration
├── pipeline.yml            # Pipeline name, schedule, default connections
└── assets/
    ├── players.asset.yml   # Ingestr asset (data ingestion)
    ├── player_stats.sql    # SQL asset with quality checks
    └── my_python_asset.py  # Python asset
```

**Understanding the default template:**
- **`players.asset.yml`**: An ingestr asset that loads chess player data into DuckDB
- **`player_stats.sql`**: A SQL asset that transforms player data with quality checks
- **`my_python_asset.py`**: A simple Python asset that prints a message

**Key concepts from this template:**
1. **Assets are the building blocks**: SQL, Python, or YAML files that represent data artifacts
2. **Dependencies define execution order**: `player_stats.sql` depends on `players`, so Bruin runs `players` first
3. **Quality checks are built-in**: `player_stats.sql` includes column checks (`not_null`, `unique`, `positive`)
4. **Connections are configured once**: `.bruin.yml` defines connections, `pipeline.yml` sets defaults

**Important**: Bruin CLI requires a git-initialized folder (uses git to detect project root); `bruin init` auto-initializes git if needed

### 2.3 Bruin CLI Commands & VS Code Extension

Now let's learn the essential commands and how to use the VS Code extension for a visual workflow.

#### Essential CLI Commands

The most common commands you'll use during development:

| Command | Purpose |
|---------|---------|
| `bruin validate <path>` | Check syntax and dependencies without running (fast!) |
| `bruin run <path>` | Execute pipeline or individual asset |
| `bruin run --downstream` | Run asset and all downstream dependencies |
| `bruin run --full-refresh` | Truncate and rebuild tables from scratch |
| `bruin lineage <path>` | View asset dependencies (upstream/downstream) |
| `bruin query --connection <conn> --query "..."` | Execute ad-hoc SQL queries |
| `bruin connections list` | List configured connections |
| `bruin connections test --name <name>` | Test connection connectivity |

**Try these commands with your default pipeline:**

```bash
# Validate the pipeline (catches errors before running)
bruin validate .

# Run the entire pipeline
bruin run .

# Run a single asset
bruin run assets/my_python_asset.py

# Run an asset with its downstream dependencies
bruin run assets/players.asset.yml --downstream

# Show the lineage for a specific asset
bruin lineage assets/players.asset.yml

# Query the resulting table
bruin query --connection duckdb-default --query "SELECT * FROM dataset.player_stats"
```

**Expected output from `bruin run .`:**
```
Starting the pipeline execution...

[18:42:58] Running:  my_python_asset
[18:42:58] Running:  dataset.players
[18:42:58] [my_python_asset] >> hello world
[18:42:58] Finished: my_python_asset (191ms)
⋮
[18:43:04] Finished: dataset.player_stats:player_count:not_null (24ms)
[18:43:04] Finished: dataset.player_stats:player_count:positive (33ms)

==================================================

PASS my_python_asset 
PASS dataset.players 
PASS dataset.player_stats .....

bruin run completed successfully in 5.439s

 ✓ Assets executed      3 succeeded
 ✓ Quality checks       5 succeeded
```

#### VS Code Extension for Visual Workflow

The Bruin VS Code extension provides a visual, interactive way to manage pipelines without memorizing CLI commands.

**Key Features:**

1. **Action Buttons**: Run and validate assets directly from the editor UI
2. **Preview Panel**: Automatically shows rendered/compiled queries (Jinja resolved, materialization applied)
3. **Syntax Highlighting**: Bruin asset definitions are highlighted for readability
4. **Autocompletion & Snippets**: Type `!fullsqlasset` or `!fullpythonasset` to generate asset templates
5. **Lineage Panel**: Visual graph showing how assets connect (bottom panel near terminal)
6. **Query Preview Panel**: Run queries and see results without leaving VS Code
7. **Database Browser**: Browse connections and table schemas from the Activity Bar

**Running Assets from VS Code:**

1. Open any asset file (`.sql`, `.py`, `.asset.yml`)
2. Look for the Bruin action buttons in the editor toolbar
3. Click **Run** to execute the asset or **Validate** to check syntax
4. The **Preview** section in the side panel automatically shows the rendered/compiled version of your query (Jinja templates resolved, materialization applied)
5. View execution results in the integrated terminal and Query Preview panel

**Using Snippets:**

- In a `.sql` file: Type `!fullsqlasset` → generates a complete SQL asset template
- In a `.py` file: Type `!fullpythonasset` → generates a complete Python asset template

**Lineage Panel:**

- Located at the bottom of VS Code (near terminal)
- Shows upstream (what the asset depends on) and downstream (what depends on the asset)
- Helps understand impact of changes before running

### 2.4 Configuration Files Deep Dive

#### `.bruin.yml`
- Defines environments (e.g., `default`, `production`)
- Contains connection credentials (DuckDB, BigQuery, Snowflake, etc.)
- Lives at the project root and **must be gitignored** because it contains credentials/secrets
  - `bruin init` auto-adds it to `.gitignore`, but double-check before committing anything

#### `pipeline.yml`
- `name`: Pipeline identifier (appears in logs, `BRUIN_PIPELINE` env var)
- `schedule`: When to run (`daily`, `hourly`, `weekly`, or cron expression)
- `start_date`: Earliest date for backfills
- `default_connections`: Platform-to-connection mappings
- `variables`: User-defined variables with JSON Schema validation

### 2.5 Connections

Connections are configured in `.bruin.yml` and referenced in `pipeline.yml` or individual assets. Default connections reduce repetition: set them once in `pipeline.yml` and all assets of that type use them automatically.

See the [Key Commands Reference](#key-commands-reference) for connection management commands.

---

## Part 3: End-to-End NYC Taxi ELT Pipeline


> **Data Availability Note**: NYC Taxi & Limousine Commission (TLC) trip data is not available after November 2025. When selecting date ranges for your pipeline, use dates before December 2025.
>
> **Development Tip**: Given the size of the parquet files (each month can be hundreds of MB), it's best to ingest **1-3 months of data** when developing and testing your pipeline. Once your pipeline is working correctly, run a full backfill for the desired years/months.
>
> **Ingesting Historical Data**: To backfill historical data, use the `--start-date` and `--end-date` flags:
> ```bash
> # Development: ingest 1-3 months
> bruin run ./pipeline/pipeline.yml --start-date 2022-01-01 --end-date 2022-03-01
>
> # Full backfill: ingest multiple years (run after pipeline is tested)
> bruin run ./pipeline/pipeline.yml --start-date 2019-01-01 --end-date 2025-11-30
> ```

### Learning Goals
- Build a complete ELT pipeline: ingestion → staging → reports
- Understand the three asset types: Python, SQL, and Seed
- Apply materialization strategies for incremental processing
- Add quality checks and declare dependencies

### 3.1 Initialize the Zoomcamp Template

Now that you understand the basics from Part 2, let's initialize 
The generated structure follows the layered architecture shown in the [Pipeline Skeleton](#pipeline-skeleton) section above. Key differences from the default template:
- **Layered structure**: Assets organized into `ingestion/`, `staging/`, and `reports/` folders
- **Real-world data source**: Fetches actual NYC taxi data from public APIs
- **Pipeline variables**: Uses `taxi_types` variable to configure which taxi types to ingest
- **Incremental strategies**: Uses `time_interval` materialization for efficient processing

### 3.2 Pipeline Architecture
- **Ingestion**: Extract raw data from external sources (Python assets, seed CSVs)
- **Staging**: Clean, normalize, deduplicate, enrich (SQL assets)
- **Reports**: Aggregate for dashboards and analytics (SQL assets)
- Assets form a DAG, and Bruin executes them in dependency order

### 3.3 Ingestion Layer
- Python asset to fetch NYC Taxi data from the TLC public endpoint
- Seed asset to load a static payment type lookup table from CSV
- Use `append` strategy for raw ingestion (handle duplicates downstream)
- Follow the TODO instructions in `pipeline/assets/ingestion/trips.py` and `pipeline/assets/ingestion/payment_lookup.asset.yml`

### 3.4 Staging Layer
- SQL asset to clean, deduplicate, and join with lookup to enrich raw trip data
- Use `time_interval` strategy for incremental processing
- Follow the TODO instructions in `pipeline/assets/staging/trips.sql`

### 3.5 Reports Layer
- SQL asset to aggregate staging data into analytics-ready metrics
- Use `time_interval` strategy and same `incremental_key` as staging for consistency
- Follow the TODO instructions in `pipeline/assets/reports/trips_report.sql`

### 3.6 Running and Validating

CLI Commands: https://getbruin.com/docs/bruin/commands/run

#### What does `validate` check?

The `bruin validate` command performs static analysis on your pipeline without executing anything:
- **Syntax validation**: Checks YAML/SQL/Python files for parsing errors
- **Schema validation**: Verifies asset definitions have required fields (name, type, etc.)
- **Dependency resolution**: Ensures all referenced dependencies exist
- **Connection references**: Validates that referenced connections are defined
- **Column definitions**: Checks column metadata syntax and types

Run `validate` frequently during development to catch errors early. It's much faster than running the full pipeline.

```bash
# Validate structure & definitions
bruin validate ./pipeline/pipeline.yml --environment default

# First-time run tip:
# Use --full-refresh to create/replace tables from scratch (helpful on a new DuckDB file).
bruin run ./pipeline/pipeline.yml --environment default --full-refresh

# Run an ingestion asset, then downstream (to test incrementally)
bruin run ./pipeline/assets/ingestion/trips.py \
  --environment default \
  --start-date 2021-01-01 \
  --end-date 2021-01-31 \
  --var taxi_types='["yellow"]' \
  --downstream



---

## Key Commands Reference

| Command | Purpose |
|---------|---------|
| `bruin init <template> <folder>` | Initialize a new project from a template |
| `bruin validate <path>` | Check syntax, schemas, dependencies without running (fast!) |
| `bruin run <path>` | Execute pipeline or asset |
| `bruin run --downstream` | Run asset and all downstream assets |
| `bruin run --full-refresh` | Truncate and rebuild from scratch |
| `bruin run --only checks` | Run quality checks without asset execution |
| `bruin query --connection <conn> --query "..."` | Execute ad-hoc queries |
| `bruin lineage <path>` | View asset dependencies |
| `bruin render <path>` | Show rendered template output |
| `bruin format <path>` | Format code |
| `bruin connections list` | List configured connections |
| `bruin connections test --name <name>` | Test connection connectivity |

---

