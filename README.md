# **Overview**

This repository provides tools for processing International Mouse Phenotyping Consortium (IMPC) genotype-phenotype data, building a MySQL database, and creating an interactive RShiny dashboard for data visualization.

## Key Features
Data Integration:

- Collating raw IMPC data from IMPC .csv files.

Database Design:

- Schema for efficient storage and querying of genotype-phenotype relationships.

Interactive Dashboard:

- Identify groups of genes with similar phenotype scores.

## Repository structure

`Group10/`

- `data/` unprocessed raw data files
  

`meta_data/`

- `IMPCSOP.csv`-> Standard Operating Procedures.
- `Disease_information.txt`-> Phenodigm disease associations.
- `IMPC_parameter_description.txt`-> Descriptions of phenotype parameters.
- `IMPC_procedure.txt`-> Details of phenotype procedures.

