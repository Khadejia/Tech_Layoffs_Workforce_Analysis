# Tech Layoffs Workforce Analysis (2020–2026)

## Project Overview

An end-to-end data analytics project analyzing global tech layoffs from 2020–2026 using PostgreSQL and Tableau. The project focuses on workforce reductions, hiring trends, geographic impact, and industry-level patterns across the technology sector.

This project demonstrates data cleaning, SQL analysis, KPI development, and interactive dashboard design for business intelligence reporting.

---

# Objectives

- Analyze global tech layoff trends from 2020–2026
- Identify the industries and countries most impacted
- Compare hiring trends against workforce reductions
- Explore company-level and regional layoff behavior
- Build interactive Tableau dashboards for analytical insights

---

# Tools & Technologies

- PostgreSQL
- SQL
- Tableau
- CSV Data Sources

---

# Data Pipeline & Dataset Information

This project follows a structured data pipeline from source data to a final analysis-ready dataset used in Tableau.

---

## Data Pipeline Overview

Source Data → Cleaning & Transformation → Final Dataset → Tableau Visualization

---


## Source Data

Located in `data/source_data/`:

- tech_layoffs_2025_2026.csv
- tech_hiring_trends_2025_2026.csv
- cleaned_tech_layoffs.csv

---

## Final Dataset (Used in Tableau)

Located in `data/final/`:

- layoffs_final.csv

The final dataset was created by merging and standardizing multiple source datasets into a single analysis-ready table for SQL analysis and Tableau visualization.

---

# SQL Workflow

The SQL workflow includes:

- Table creation
- Data validation
- Duplicate removal
- Data cleaning
- Exploratory data analysis
- KPI generation
- Tableau-ready query preparation

---

# Business Questions

- Which industries experienced the highest layoffs?
- Which countries were most affected?
- Which companies had the largest workforce reductions?
- How did hiring trends compare against layoffs?
- Did layoffs increase during specific years or quarters?
- Which departments experienced the most reductions?

---

# Key Insights

- Large-scale layoffs peaked during major market correction periods.
- U.S.-based companies represented a significant portion of reported layoffs.
- Workforce reductions varied heavily across industries and company stages.
- Hiring activity continued in selected technical areas despite broader layoffs.

---

# Live Dashboard

[View Interactive Tableau Dashboard](https://public.tableau.com/views/Tech_layoffs_17797363566980/Summary?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

# Dashboard Previews

## Workforce Impact Overview Dashboard

<img width="1199" height="1099" alt="Summary" src="https://github.com/user-attachments/assets/425fb38b-6cc4-4784-84f7-be5bc1da5759" />

---

## Company Records Dashboard

<img width="1199" height="1099" alt="Records" src="https://github.com/user-attachments/assets/8db85eb4-46cd-4192-832d-211181a6b6ba" />

---

# Dashboard Features

The Tableau solution contains two interactive dashboards focused on executive KPIs, workforce reductions, geographic trends, hiring activity, and company-level analysis.

Dashboard features include:

- KPI cards
- Layoff trend analysis
- Geographic analysis
- Industry breakdowns
- Company comparisons
- Hiring vs layoffs analysis
- Interactive filters and search functionality

---

# Repository Structure

```text
tech-layoffs-project/
│
├── data/
│   ├── source_data/
│   │   ├── tech_layoffs_2025_2026.csv
│   │   ├── tech_hiring_trends_2025_2026.csv
│   │   └── cleaned_tech_layoffs.csv
│   │
│   └── final/
│       └── layoffs_final.csv
│
├── sql/
│   └── tech_layoffs.sql
│
└── README.md
```

---

# Technical Skills Demonstrated

- SQL data cleaning
- PostgreSQL database management
- Aggregations and joins
- Common Table Expressions (CTEs)
- Window functions
- KPI development
- Interactive dashboard design
- Data visualization
- Data storytelling
