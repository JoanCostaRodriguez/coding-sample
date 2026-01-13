# Municipality-Level GDP and Population matching

**Author:** Joan Costa  
**Purpose:** Coding sample

## Overview

This repository constructs a municipality-level panel of **GDP per capita** by combining historical GDP and population data across multiple benchmark years, it is a modified and adapted sample of my awarded thesis: "Market Access and Regional Inequality: Evidence from Brazil's Capital Relocation".
In this sample I show how I constructed the GDP per capita for the later construction of the inequality indices facing some problems with the raw data available.

The main task is entity harmonization: municipality names differ across official sources and over time. The pipeline implements a transparent and conservative matching procedure (exact + fuzzy) and outputs an analysis-ready dataset with GDP per capita.

## What this repo demonstrates

- Reproducible, modular R pipeline (single entry point via `run_all.R`)
- Transparent matching logic with auditable diagnostics
- Conservative fuzzy matching with one-to-one assignment
- Clean, analysis-ready output with GDP per capita

## Data

All the data is extracted from official sources such as the IBGE (Instituto Brasileiro de Geografia e Estatística).

It follows the structure:
```text
data/
└── raw/
    ├── gdp_1939.xlsx
    ├── gdp_1950.xlsx
    ├── gdp_1960.xlsx
    ├── gdp_1970.xlsx
    ├── gdp_1975.xlsx
    ├── gdp_1980.xlsx
    ├── gdp_1996.xlsx
    ├── population_1940_clean.xlsx
    ├── population_1950_clean.xlsx
    ├── population_1960_clean.xlsx
    ├── population_1970_clean.xlsx
    ├── population_1976_clean.xlsx
    ├── population_1980_clean.xlsx
    └── population_1992_clean.xlsx
```

Each GDP file contains:
- a municipality identifier (`Codigo`)
- a municipality name (`Municipality`)
- a GDP value column for the specified year (e.g., `"1939"`)

Each population file contains:
- municipality name (`Municipality`)
- population (`Population`)
- province/state identifier (`State`)

## Methodology

1. **Standardize municipality names**  
   Uppercase, remove punctuation, remove accent marks, normalize whitespace.

2. **Exact match**  
   Deterministic merge on standardized names.

3. **Fuzzy match for remaining cases**  
   - Compute string distances (Optimal String Alignment, OSA) between remaining unmatched names  
   - Keep candidates within a distance threshold  
   - Select matches using a greedy one-to-one assignment

4. **Construct GDP per capita**  
   `gdp_pc = gdp_value / population`  
   Drop observations with missing/invalid values (e.g., non-positive population).  
   Drop unmatched GDP municipalities (reported in the year summary).

## Outputs

Running the pipeline produces:

- `output/matched_municipality_panel.csv`  
  Analysis-ready panel with GDP per capita.

- `output/matching_summary_by_year.csv`  
  Diagnostics per year (exact matches, fuzzy matches, dropped/unmatched counts).

- `output/figures/sanity_log_gdp_pc_by_year.png`  
  Sanity check plot: distribution of log GDP per capita by year.

### Main dataset schema

`output/matched_municipality_panel.csv` includes:

- `code` — municipality identifier
- `year`
- `municipality`
- `state`
- `population`
- `gdp_value`
- `gdp_pc`
- `match_type` — `"Exact"` or `"Fuzzy"`
- `dist` — string distance (NA for exact matches)

## Project structure
```text
R/
├── 00_packages.R        # Load required packages
├── 01_paths.R           # Centralized path definitions (raw data read-only)
├── 10_matching.R        # Exact + conservative fuzzy matching; GDP per capita construction
├── 20_build_panel.R     # Year-by-year execution wrapper
├── 30_checks.R          # Diagnostic and integrity checks
├── 40_sanity_plot.R     # Sanity-check plots
run_all.R                # Single entry point (runs full pipeline)
output/
└── (generated)          # Automatically created outputs
```
## How to run

1. Open the project root (recommended via an `.Rproj` file).
   
2. Run: `run_all.R`

## Sanity check

The plot output/figures/sanity_log_gdp_pc_by_year.png shows:

- log(GDP per capita) is finite (no obvious zeros/inf/NaNs)

- Distributions across years are plausible (no extreme scaling jumps)

- No gross unit errors (e.g., values off by orders of magnitude)

## Notes

GDP and population years do not always coincide exactly (e.g., GDP 1939 with population 1940), reflecting the structure of the original sources.

Fuzzy matching is intentionally conservative: ambiguous cases are excluded rather than forced and would require a closer look.

## Disclaimer

This repository is intended as a coding sample demonstrating data construction, reproducibility, and transparent matching decisions. It is not a finalized research dataset neither the completed project.


