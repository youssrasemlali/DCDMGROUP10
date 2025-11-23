# **Overview**

This repository provides tools for processing International Mouse Phenotyping Consortium (IMPC) genotype-phenotype data, building a MySQL database, and creating an interactive RShiny dashboard for data visualization.

## Key Features
Data Integration:

- Collating raw IMPC data from IMPC .csv files.
- Cleaning data according to SOP 

Database Design:

- Schema for efficient storage and querying of genotype-phenotype relationships.

Interactive Dashboard:

- Identify groups of genes with similar phenotype scores.

## Repository structure

`Group10/data/` -> unprocessed raw data files

`Scripts/`

- `Cleaning_according_to_SOP.qmd` ->  Cleans collated data according to SOP constraints
- `clean_impc_parameters.qmd` -> Cleans parameters file to ensure compatibility with the database schema
- `clean_impc_procedure.qmd` -> Cleans procedure file to ensure compatibility with the database schema
- `collating_raw_data_script.qmd` -> data collation checkig data types for each column and merging data into unified dataframe
- `disease_info_clean_updated_script.qmd` -> Cleans disease information file to ensure compatibility with the database schema

  

`meta_data/`

- `IMPCSOP.csv`-> Standard Operating Procedures.
- `Disease_information.txt`-> Phenodigm disease associations.
- `IMPC_parameter_description.txt`-> Descriptions of phenotype parameters.
- `IMPC_procedure.txt`-> Details of phenotype procedures.

`rshiny/`

- `impc_app.R` -> rshiny script producing visualisations 


`sql/`

- `IMPC_phenotype_db_dump.sql` -> database dump
- `Script-13-updated.sql` -> script creating database tables and populating tables
- `impc_phenotype_db.png` -> SQL database


