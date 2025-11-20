drop database if exists IMPC_phenotype_db; 
create database if not EXISTS IMPC_phenotype_db;

use impc_phenotype_db;


create table Genes(
	gene_id INT auto_increment primary key,
	gene_accession_id VARCHAR(50) not null UNIQUE, -- this is also the mgi acession ID
	gene_symbol VARCHAR (100) not null
);
#Reasoning, gene_id is the surrogate pk
-- one to many
#Table is central references for all the mouse genes (MGI)

-- load data from IMPC_cleaned_data.csv into genes tables

-- have needed to add a staging table in order to deal with duplicate genes
-- staging table for deduplication


CREATE TEMPORARY TABLE temp_genes (
    gene_accession_id VARCHAR(50),
    gene_symbol VARCHAR(100)
);


load data local infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
INTO table temp_genes
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 rows
(@col1, @col2, @col3, @col4,@col5,@col6,@col7, @col8)
SET
	gene_accession_id = @col2,
	gene_symbol = @col3;

-- selecting distinct genes
-- the realtionship between the gene and the parameter needs to happen in the phenotype_analysis table
INSERT INTO Genes (gene_accession_id, gene_symbol)
SELECT DISTINCT gene_accession_id, gene_symbol
FROM temp_genes;

DROP TEMPORARY TABLE temp_genes;



-- check
select * from Genes;

#TRUNCATE table Genes;


-- stores human disease
create table Disease_ontology(
	Disease_id INT not null auto_increment primary key, 
	DO_disease_id VARCHAR(50) not null,
	DO_disease_name VARCHAR(500) not null,
	OMIM_IDs VARCHAR(100)
);

 -- OMIM to big for datatype and try load data again
 alter table Disease_ontology
 modify column OMIM_IDs TEXT;


load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DI_clean_updated.csv'
INTO table Disease_ontology
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(@col1, @col2, @col3, @col4)
SET
	DO_disease_id = @col1,
	DO_disease_name = @col2,
	OMIM_IDs = @col3;



select * from Disease_ontology
select * from disease_ontology where DO_disease_id ='DOID:14221';
select * from disease_ontology where Disease_id= '1';
select * from Gene_disease_association where gene_id = '6';
select * from disease_ontology where disease_id ='976';


-- Table 3
create table Gene_disease_association (
	gene_disease_id INT auto_increment primary key,
	gene_id INT not null,
	Disease_id INT not null,
	foreign key (gene_id) references genes(gene_id),
	foreign key (Disease_id) references disease_ontology (Disease_id),
	UNIQUE KEY unique_gene_disease (gene_id, Disease_id)
);

-- create a staging table
CREATE TABLE IF NOT EXISTS DI_stage (
    DO_disease_id VARCHAR(200),
    DO_disease_name VARCHAR(500),
    OMIM_IDs TEXT,
    gene_accession VARCHAR(200)
);

#loaded the csv file into 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DI_clean_updated.csv'
INTO TABLE DI_stage
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 rows
(@col1, @col2, @col3, @col4)
set 
	DO_disease_id = @col1,
	DO_disease_name = @col2,
	OMIM_IDs = @col3,
	gene_accession = @col4;



INSERT INTO Gene_disease_association (gene_id, Disease_id)
SELECT 
	g.gene_id,
	d.Disease_id
FROM DI_stage s
inner JOIN Genes g ON g.gene_accession_id = s.gene_accession
inner JOIN Disease_ontology d ON d.DO_disease_id = s.DO_disease_id 
WHERE s.gene_accession  IS NOT NULL 
	AND s.gene_accession <> '';

-- Links the disease to the associated gene
-- import DI_clean_seperated
-- 2 foreign keys for many-to-many relationship between genes and disease
-- This is the joining table

-- example queries

select count(*) from Gene_disease_association
	
SELECT 
    g.gene_symbol,
    g.gene_accession_id,
    d.DO_disease_name,
    d.OMIM_IDs
FROM Gene_disease_association gda
JOIN Genes g ON g.gene_id = gda.gene_id
JOIN Disease_ontology d ON d.Disease_id = gda.Disease_id
LIMIT 10;
 -- 


-- TABLE 4
-- trying to represent a one to many relationship, one procedure can have seeveral parameters

CREATE TABLE procedures (
    procedure_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(250) NOT NULL,
  	procedure_description TEXT,
    is_mandatory BOOLEAN DEFAULT false,
    impc_parameter_id INT
);


-- staging table
CREATE TABLE temp_procedures (
    procedure_name VARCHAR(250),
    procedure_description TEXT,
    is_mandatory VARCHAR(10),
    impc_parameter_id INT
);
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_procedure_clean.csv'
INTO TABLE temp_procedures
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- used varchar in order to accept true and false

-- now laoding into procedures table

INSERT INTO Procedures (procedure_name, procedure_description, is_mandatory, impc_parameter_id)
SELECT 
    procedure_name,
    procedure_description,
    CASE WHEN UPPER(is_mandatory) = 'TRUE' THEN 1 ELSE 0 END,
    impc_parameter_id
FROM temp_procedures;


-- Table 5
create table parameters (
	parameter_id INT auto_increment primary key, -- ref this at pt_analysis table
	parameterId VARCHAR(50) not null, -- col 4 in parameter csv --refered to as parameter_code previosuly --IMPC parameter identifier
	impc_parameter_orig_id INT, -- link to procedures
	parameter_name VARCHAR(200),
    parameter_description TEXT,
    procedure_id INT, -- FK to procedures
    FOREIGN KEY (procedure_id) REFERENCES procedures (procedure_id)
);
 

#drop table parameters;

	
#create a temp staging table in order to load paramater and procedure column into parameters table	
#staging table should mirror the the csv file not the table

-- staging table
CREATE TABLE temp_parameters (
	impc_Parameter_Orig_Id INT,
  	parameter_name VARCHAR(200),
    parameter_description TEXT,
    parameterId VARCHAR (50)
);

#drop table temp_parameters;

#The csv data from parameters.csv is loaded in the staging table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
INTO TABLE temp_parameters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


#Data laoded into staging table
#Insert the parameters and procedure_id

INSERT INTO Parameters (
    parameterId, 
    impc_parameter_orig_id, 
    parameter_name, 
    parameter_description, 
    procedure_id
)
SELECT 
    tp.parameterId,
    tp.impc_Parameter_Orig_Id,
    tp.parameter_name,
    tp.parameter_description,
    p.procedure_id
FROM temp_parameters tp
LEFT JOIN Procedures p 
    ON p.impc_parameter_id = tp.impc_Parameter_Orig_Id;


-- table 6

#this table helps to group the related paramters we want into one table
#Defines our groups a
create table parameter_groupings(
	group_id INT AUTO_increment primary key,
	group_name VARCHAR(100) not null unique,
	group_description TEXT
);


-- Insert the parameter groups
INSERT INTO Parameter_groupings (group_name, group_description)
VALUES
    ('Weight', 'Body weight and organ weight measurements'),
    ('Imaging', 'Parameters with imaging-based measurements'),
    ('Brain', 'Brain morphology and neurological parameters'),
    ('Bone', 'Bone density, mineral content and skeletal structure parameters'),
    ('Haematology', 'Complete blood count and blood chemistry parameters'),
    ('Cardiovascular', 'Heart function, ECG, blood pressure, and cardiac morphology'),
    ('Vision', 'Eye morphology, retinal structure, lens parameters, and vision tests'),
    ('Immunology', 'Immune system cell counts and function'),
    ('Limb function', 'Function of various limbs');

SELECT * FROM Parameter_groupings;
-- The group_id is the PK that we made, identify each grouping this way



-- table 7
-- This is a junction table, many to many relationship
-- Allows individual paramaters to link to the groups we made in the parameter_groupings table


create table parameter_group_linking (
	linking_id INT auto_increment primary key,
	parameter_id INT not null,
	group_id INT not null,
	foreign key (parameter_id) references parameters(parameter_id),
	foreign key (group_id) references parameter_groupings(group_id)
);

#drop table parameter_group_linking;
 -- insert the parameters related to weight 

INSERT INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
FROM Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Weight'
    AND (LOWER(p.parameter_name) LIKE '%weight%'
    OR LOWER(p.parameter_name) LIKE '%mass%');

-- images
insert INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
FROM Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Imaging'
    AND (LOWER(p.parameter_name) LIKE '%image%'
    OR LOWER(p.parameter_name) LIKE '%scan%'
    OR LOWER(p.parameter_name) LIKE '%x-ray%');

-- brain

INSERT INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
FROM Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Brain'
    AND (LOWER(p.parameter_name) LIKE '%brain%'
    OR LOWER(p.parameter_name) LIKE '%neural%'
    OR LOWER(p.parameter_name) LIKE '%forebrain%'
    OR LOWER(p.parameter_name) LIKE '%cortex%'
    OR LOWER(p.parameter_name) LIKE '%Hippocampus%'
    OR LOWER(p.parameter_name) LIKE '%Hypothalamus%'
    OR LOWER(p.parameter_name) LIKE '%Hippocampus%'
    OR LOWER(p.parameter_name) LIKE '%Nerve%');

-- immunology

insert into Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
from Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Immunology'
    AND (LOWER(p.parameter_name) LIKE '%nk cells%'
    OR LOWER(p.parameter_name) LIKE '%leukocyte%'
    OR LOWER(p.parameter_name) LIKE '%white blood cell%'
    OR LOWER(p.parameter_name) LIKE '%Tcells%'
    OR LOWER(p.parameter_name) LIKE '%cd45%'
    OR LOWER(p.parameter_name) LIKE '%cd4%'
    OR LOWER(p.parameter_name) LIKE '%lymphocyte%'
	OR LOWER(p.parameter_name) LIKE '%B cells%');

-- haematology

insert into Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
from Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Haematology'
    AND (LOWER(p.parameter_name) LIKE '%iron%'
    OR LOWER(p.parameter_name) LIKE '%sodium%'
    OR LOWER(p.parameter_name) LIKE '%hdl%'
    OR LOWER(p.parameter_name) LIKE '%cholesterol%'
    OR LOWER(p.parameter_name) LIKE '%platelet%'
    OR LOWER(p.parameter_name) LIKE '%albumin%'
    OR LOWER(p.parameter_name) LIKE '%hemoglobin%'
    OR LOWER(p.parameter_name) LIKE '%hematocrit%'
    OR LOWER(p.parameter_name) LIKE '%red blood cell%');
 	
 	-- bone
insert INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
from Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Bone'
    AND (LOWER(p.parameter_name) LIKE '%skeletal%'
    OR LOWER(p.parameter_name) LIKE '%bone%'
    OR LOWER(p.parameter_name) LIKE '%rib%'
    OR LOWER(p.parameter_name) LIKE '%mineral%'
    OR LOWER(p.parameter_name) LIKE '%skull%'
    OR LOWER(p.parameter_name) LIKE '%tibia%'
    OR LOWER(p.parameter_name) LIKE '%pelvis%'
    OR LOWER(p.parameter_name) LIKE '%craniofacial%');

 -- cardio
INSERT INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
FROM Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Cardiovascular'
    AND (LOWER(p.parameter_name) LIKE '%heart%'
    OR LOWER(p.parameter_name) LIKE '%cardiac%'
    OR LOWER(p.parameter_name) LIKE '%cardio%'
    OR LOWER(p.parameter_name) LIKE '%valve%'
	OR LOWER(p.parameter_name) LIKE '%atrium%');

 -- Vision

insert INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
from Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Vision'
    AND (LOWER(p.parameter_name) LIKE '%eye%'
    OR LOWER(p.parameter_name) LIKE '%retina%'
    OR LOWER(p.parameter_name) LIKE '%lens%'
    OR LOWER(p.parameter_name) LIKE '%vision%'
    OR LOWER(p.parameter_name) LIKE '%optic%'
	or LOWER(p.parameter_name) like '%Iris%');

-- limb function
insert INTO Parameter_group_linking (parameter_id, group_id)
SELECT 
    p.parameter_id,
    pg.group_id
from Parameters p
CROSS JOIN Parameter_groupings pg
WHERE pg.group_name = 'Limb function'
    AND (LOWER(p.parameter_name) LIKE '%strength%'
    OR LOWER(p.parameter_name) LIKE '%grip%'
    OR LOWER(p.parameter_name) LIKE '%locomotor%');


-- Last table -- Table 8
-- joining table
create TABLE phenotype_analyses(
	analysis_id VARCHAR(50) primary key,
	gene_id INT not null, -- loaded in from Genes
	parameter_id INT not null, -- matches parameters table pk
	mouse_strain VARCHAR(50) not null,
	life_stage VARCHAR (50) not null,
	pvalue DOUBLE, -- chnaged to decimal, better prescion
	
	foreign key (gene_id) references Genes(gene_id),
	foreign key (parameter_id) references parameters(parameter_id)
);

#This table includes data from IMPC_cleaned_data (the phenotype data).
# Includes gene info, and the parameters tested.p value is included, this shows us the association score between the knockout gene and the phenotype

-- load staging table

create table temp_phenotype (
    analysis_id VARCHAR(50),
    gene_accession_id VARCHAR(50),
    gene_symbol VARCHAR(50),
    mouse_strain VARCHAR(50),
    life_stage VARCHAR(50),
    parameterId VARCHAR(50),
    parameter_name VARCHAR(250),
    pvalue DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
INTO TABLE temp_phenotype
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, gene_symbol, mouse_strain, 
 life_stage, parameterId, parameter_name, pvalue);

-- load into joining table
INSERT ignore INTO Phenotype_analyses (
    analysis_id,
    gene_id,
    parameter_id,
    mouse_strain,
    life_stage,
    pvalue
)
SELECT 
    tp.analysis_id,
    g.gene_id,
    p.parameter_id,
    tp.mouse_strain,
    tp.life_stage,
    tp.pvalue
FROM temp_phenotype tp
INNER JOIN Genes g 
    ON g.gene_accession_id = tp.gene_accession_id
INNER JOIN Parameters p
    ON p.parameterId = tp.parameterId;

#TRUNCATE TABLE Phenotype_analyses;

-- dropped staging tables
drop table temp_phenotype;
drop table temp_procedures;
drop table temp_parameters;
drop table di_stage;

-- ----------------------------------------------

-- checks 

SELECT COUNT(*) FROM Phenotype_analyses;

SELECT 'Checking Genes...' AS status, COUNT(*) FROM Genes;
SELECT 'Checking parameters...' AS status, COUNT(*) FROM parameters;
SELECT 'Records inserted:' AS status, COUNT(*) FROM phenotype_analyses;



SELECT * FROM Phenotype_analyses WHERE analysis_id = '1cbwok0z6011606';

SELECT 'Genes' AS table_name, COUNT(*) AS row_count FROM Genes
UNION ALL
SELECT 'Disease_ontology', COUNT(*) FROM Disease_ontology
UNION ALL
SELECT 'Gene_disease_association', COUNT(*) FROM Gene_disease_association
UNION ALL
SELECT 'Procedures', COUNT(*) FROM Procedures
UNION ALL
SELECT 'Parameters', COUNT(*) FROM Parameters
UNION ALL
SELECT 'Parameter_groupings', COUNT(*) FROM Parameter_groupings
UNION ALL
SELECT 'Parameter_group_linking', COUNT(*) FROM Parameter_group_linking
UNION ALL
SELECT 'Phenotype_analyses', COUNT(*) FROM Phenotype_analyses;

-- --------------------------------------------------

-- Queries


SHOW DATABASES LIKE 'impc_phenotype_db';

SHOW TABLES IN impc_phenotype_db;

DESCRIBE Genes;
DESCRIBE Disease_ontology;
DESCRIBE Gene_disease_association;
DESCRIBE Procedures;
DESCRIBE Parameters;
DESCRIBE Parameter_groupings;
DESCRIBE Parameter_group_linking;
DESCRIBE Phenotype_analyses;

SELECT COUNT(*) FROM Genes;

SELECT gene_accession_id, COUNT(*)
FROM Genes
GROUP BY gene_accession_id
HAVING COUNT(*) > 1;

SELECT * FROM Genes LIMIT 20;

select * from Genes where gene_symbol = 'EYA3';

select * from disease_ontology where DO_disease_id = 'DOID:0112248'









