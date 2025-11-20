drop database if exists IMPC_phenotype_db; 
create database if not EXISTS IMPC_phenotype_db
-- character set utf8mb4
-- collate utf8mb4_unicode_ci;

use impc_phenotype_db;


create table Genes(
	gene_id INT auto_increment primary key,
	gene_accession_id VARCHAR(50) not null, -- this is also the mgi acession ID
	gene_symbol VARCHAR (100) not null
);
#Reasoning, gene_id is the surrogate pk
#gene_acession must be unique, each acession represents a gene
#gene symbol is not null as 
#central table for mouse genes

load data local infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
INTO table Genes
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 rows
(@col1, @col2, @col3, @col4,@col5,@col6,@col7, @col8)
SET
	gene_accession_id = @col2,
	gene_symbol = @col3;

select * from Genes;

TRUNCATE table Genes;

 -- show VARIABLES like 'secure_file_priv';

 -- drop TABLE Genes;

-- select gene_accession_id,
	COUNT (*) as Occurrences
from Genes
group by gene_accession_id 
having COUNT (*) > 1;


#one to many realationship
#Table is central references for all the mouse genes (MGI)
#Import data from DI_clean and IMPC_cleaned_data

-- stores huamnd disease
create table Disease_ontology(
	Disease_id INT not null auto_increment primary key, 
	DO_disease_id VARCHAR(50) not null,
	DO_disease_name VARCHAR(500) not null,
	OMIM_IDs VARCHAR(100)
);

#Human disease from DO with OMIM. This has the disease information
#Disease id and name. THE OMIM identifier and Mouse gene ID

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

 -- OMIM to big for datatype and try load data again
 alter table Disease_ontology
 modify column OMIM_IDs TEXT;


select * from Disease_ontology

select * from disease_ontology where DO_disease_id ='DOID:14221';

select * from disease_ontology where Disease_id= '1';

#Realised that seperating the DI_clean data has produced duplicates 

TRUNCATE table Disease_ontology

DROP TABLE disease_ontology;
#Dropped the table to start again, put in a wrong column



select * from Gene_disease_association where gene_id = '6';

select * from disease_ontology where disease_id ='976';

create table Gene_disease_association (
	gene_disease_id INT auto_increment primary key,
	gene_id INT not null,
	Disease_id INT not null,
	foreign key (gene_id) references genes(gene_id),
	foreign key (Disease_id) references disease_ontology (Disease_id),
	UNIQUE KEY unique_gene_disease (gene_id, Disease_id)
);

--- LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DI_clean_updated.csv'
INTO TABLE Gene_disease_association
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@col1, @col2, @col3, @col4)
SET
    gene_id = (SELECT gene_id FROM Genes WHERE gene_accession_id = @col2),
    Disease_id = (SELECT Disease__id FROM Disease_ontology WHERE DO_disease_id = @col1)
WHERE @col4 IS NOT NULL AND @col4 != '';


#create a staging table
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
	g.gene_id, d.Disease_id
FROM DI_stage s
JOIN Genes g ON g.gene_accession_id = s.gene_accession
JOIN Disease_ontology d ON d.DO_disease_id = s.DO_disease_id 
WHERE s.gene_accession  IS NOT NULL 
	AND s.gene_accession <> '';

#can drop the staging table after
#kept it in for explanantion

drop table di_stage;
#Links the disease to the associated gene
#import DI_clean_seperated
#2 foreign keys for many-to-many relationship between genes and disease
#This is the joining table
#dont think i have to laod data here 

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


-- trying to represent a one to many relationship, one procedure can have seeveral parameters
 -- excluded impc)paramter_id, does no normalize
CREATE TABLE procedures (
    procedure_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(250) NOT NULL,
  	procedure_description TEXT,
    is_mandatory BOOLEAN DEFAULT false 
    -- procedure_code VARCHAR (50) not null, -- this is parameterid from the parameter.csv ex(IMPC)
    -- impc_parameter_id INT not null -- THIS IS col4 of the procedures table, added this to link
);


#parameter_id is the IMPC to link parameter (phenotypes) to the procedures
#procedure_code represents the parameter found in the paramater.csv
#procedure_code (paramaterId) links the parameters to the procedures

#In the procedure csv. the IMPC_parameter_id is the procedure_code in this table

select if (is_mandatory, 'TRUE', 'FALSE') as my_bool
from procedures
#Meant to convert 1/0 to true and false respectively


load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_procedure_clean.csv'
INTO table procedures
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(@col1, @col2, @col3, @col4)
SET
	procedure_name = @col1,
	procedure_description = @col2,
	is_mandatory = case when UPPER(@col3) = 'TRUE' then true else false end
;

#loading was successful
#false is a string, isnt automatically converted to an int
#code converts the true/false string into 1/0

drop table procedures;

#load data wont let me update to add additoal column from other csv
#Must make a temp table






create table parameters (
	parameter_id INT auto_increment primary key, -- ref this at pt_analysis table
	parameterId VARCHAR(50) not null unique, -- col 4 in parameter csv --refered to as parameter_code previosuly --wil link pt results
	impc_parameter_orig_id INT, -- link to procedures
	parameter_name VARCHAR(200),
    parameter_description TEXT,
    procedure_id INT, -- FK to procedures
    FOREIGN KEY (procedure_id) REFERENCES procedures (procedure_id)
);
 
-- altered so i could compare the impc_parameter_ids from both procedures and parameters
ALTER TABLE parameters 
    MODIFY impc_parameter_orig_id VARCHAR(50);




#this didnt work
#load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
#INTO table parameters
#FIELDS terminated by ','
#enclosed by '"'
#lines terminated by '\n'
#IGNORE 1 ROWS
#(@col1, @col2, @col3, @col4)
#SET
	#impc_parameter_orig_id = @col1,
	#parameter_name = @col2,
	#parameter_description = @col3;
	
	
#create a temp staging table in order to load paramater and procedure column into parameters table	
#staging table should mirror the the csv file not the table


CREATE TABLE temp_parameters (
    parameterId INT,
    parameter_name VARCHAR(200),
    parameter_description TEXT,
    impc_Parameter_Orig_Id VARCHAR(50)
);



#The csv data from parameters.csv is loaded in the staging table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
INTO TABLE temp_parameters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



drop table temp_parameters;
#made a mistake, dropped the table

#Data laoded into staging table
#Insert the parameters and procedure

 
-- CORRECT VERSION
#other version #not using, will get rid of
INSERT INTO Parameters (
	parameterId, 
	impc_parameter_orig_id, 
	parameter_name, 
	parameter_description, 
	procedure_id
)

SELECT * from (
	SELECT
    temp_parameters.col4 as parameterId,
    temp_parameters.col1 as impc_parameter_orig_id,
    temp_parameters.col2 as parameter_name,
    temp_parameters.col3 as parameter_description,
    procedures.procedure_id as procedure_id
FROM temp_parameters
LEFT JOIN Procedures 
	ON procedures.procedure_id = temp_parameters.col4
)
AS new
ON DUPLICATE KEY UPDATE 
    parameter_name = new.parameter_name,
    parameter_description = new.parameter_description;

#tried to use on duplicate alone had issues
#had to use AS new
#also had to change the layout/pattern, issues with AS new

drop table parameters;

-- join failed from code above , procedure_id is null in parameter table



-- Make a temp procedures table (this was meant to fix the null procedure-id in my parameters table but still didnt work)
-- load temp procedure table

CREATE TEMPORARY TABLE temp_procedures (
    procedure_name VARCHAR(255),
    procedure_description TEXT,
    is_mandatory VARCHAR(10),
    impc_parameter_id VARCHAR(50)
);

ALTER TABLE temp_procedures 
    MODIFY impc_parameter_id VARCHAR(50); -- dont need to run this as i change dtable

-- had to alter impc_parameter_id to a varchar in order to comapre them


LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_procedure_clean.csv'
INTO TABLE temp_procedures
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

INSERT IGNORE INTO procedures (procedure_name, procedure_description, is_mandatory)
SELECT DISTINCT 
    procedure_name,
    procedure_description,
    CASE WHEN is_mandatory = 'TRUE' THEN 1 ELSE 0 END
FROM temp_procedures;

-- succesffuly loaded info into temp_procedures above

-- tried other code below

SELECT COUNT(*) FROM procedures; -- queries not part of code
SELECT * FROM procedures WHERE procedure_name = 'Grip Strength';

INSERT INTO parameters 
    (parameterId, parameter_name, parameter_description, impc_parameter_orig_id, procedure_id)
SELECT 
    tp.parameterId AS parameterId,
    tp.parameter_name AS parameter_name,
    tp.parameter_description AS parameter_description,
    tp.impc_Parameter_Orig_Id AS impc_parameter_orig_id,
    p.procedure_id
FROM temp_parameters tp
LEFT JOIN temp_procedures tproc 
    ON tp.impc_Parameter_Orig_Id = tproc.impc_parameter_id
LEFT JOIN procedures p 
    ON tproc.procedure_name = p.procedure_name;


-- its still null (procedure_id) didnt work 



-- ----------------------------------------------

#this table helps to group the related paramters we want into one table
#Defines our groups a
create table parameter_groupings(
	group_id INT AUTO_increment primary key,
	group_name VARCHAR(100) not null unique,
	group_description TEXT
);



#drop table parameter_groupings;
	
insert into parameter_groupings (group_name,group_description) 
values
('Weight ','Body weight and organ weight measurements' ),
('Imaging','Parmeters with imaging-based measurements'),
('Brain', 'Brain morphology and neurological parameters'),
('Bone','Bone density, mineral content and skeletal structure parameters'),
('Haematology','Complete blood count and blood chemistry parameters'),
('Cardiovascular function', 'Heart function, ECG, blood pressure, and cardiac morphology'),
('Vision', 'Eye morphology, retinal structure, lens parameters, and vision tests');



#The group_id is the PK that we made, identify each grouping this way
#Groupings are Weight, Images abd brain
#Additional groups, cardiac, haematology, Bone/skeletal
#Body weight,spleen weight, liver weight, heart weight, lean mass, fat mass
#Imaging
#brain, locomotor activity, 18khz-evoked abr threshold, forebrain
#kidney, total bilirubin
#enzymes/liver/kidney, ALP, ALT,
#teeth, incisor
#Haematology, iron, calcium, hdl cholesterol, mean platelet volume,Total cd4+ t cells - % of cd45+, WBC count, albumin, hemoglobin, hematocrit
#vision
#Bone, bone mineral content (excluding skull), shape of ribs, tibia length, craniofacial morphology, pelvis
#Immunology


#This is a junction table, many to many relationship
#Allows individual paramaters to link to the groups we made in the parameter_groupings table
create table parameter_group_linking (
	linking_id INT auto_increment primary key,
	parameter_id INT not null,
	group_id INT not null,
	foreign key (parameter_id) references parameters(parameter_id),
	foreign key (group_id) references parameter_groupings(group_id)
);

drop table parameter_group_linking;
 -- insert the parameters related to weight 

insert into parameter_group_linking (parameter_id, group_id)
select 
	parameters.parameter_id,
	parameter_groupings.group_id
from parameters 
Join parameter_groupings 
where parameter_groupings.group_name = 'Weight'
	and (LOWER(parameters.parameter_name) like '%weight%'
	or LOWER(parameters.parameter_name) like '%mass%');


-- Imaging
insert into parameter_group_linking (parameter_id, group_id)
select 
	parameters.parameter_id,
	parameter_groupings.group_id
from parameters 
join 
	parameter_groupings on parameter_groupings.group_name = 'Image'
where
	lower(parameters.parameter_name) like '%Image%'
	or lower(parameters.parameter_name) like '%scan%';
 
	-- brain
insert into parameter_group_linking (parameter_info_id, group_id)

select 
	parameters.parameter_info_id
	parameter_groupings.group_id
from parameters 
join parameter_groupings on parameter_groupings.group_name = 'Brain'
or lower(parameters.parameter_name) like '%Neural%',
	or LOWER(parameters.paramater_name) like '%%';


-- immunology

insert into parameter_group_linking (parameter_info_id, group_id)
select 
	parameters.parameter_info_id
	parameter_groupings.group_id
from parameters 
join parameter_groupings on parameter_groupings.group_name = 'Immunology'
or lower(parameters.parameter_name) like '%NK cells%',
	or LOWER(parameters.paramater_name) like '%leukocytes%'
	or LOWER(parameters.paramater_name) like '%white blood cell_count%'
	or LOWER(parameters.paramater_name) like '% t cells%'
	or LOWER(parameters.paramater_name) like '%cd45+%';

-- haematology

insert into parameter_group_linking (parameter_info_id, group_id)

select 
	parameters.parameter_info_id
	parameter_groupings.group_id
from parameters 
join parameter_groupings on parameter_groupings.group_name = 'Haematology'
or lower(parameters.parameter_name) like '%Iron%',
	or LOWER(parameters.paramater_name) like '%Sodium%'
	or LOWER(parameters.paramater_name) like '%Hdl-cholesterol%'
	or LOWER(parameters.paramater_name) like '%Mean platelet volume%'
 	or LOWER(parameters.paramater_name) like '%Ablumin%'
	or LOWER(parameters.paramater_name) like '%Hemoglobin%'
 	or LOWER(parameters.paramater_name) like '%Red blood cell%'
 	
 	-- bone
insert into parameter_group_linking (parameter_info_id, group_id)

select 
	parameters.parameter_info_id
	parameter_groupings.group_id
from parameters 
join parameter_groupings on parameter_groupings.group_name = 'Bones'
or lower(parameters.parameter_name) like '%skeletal%',
	or LOWER(parameters.paramater_name) like '%Shape of ribs%'
	or LOWER(parameters.paramater_name) like '% mineral density%'
	or LOWER(parameters.paramater_name) like '%Skull shape%'

 	
	-- Enzymes
insert into parameter_group_linking (parameter_info_id, group_id)

select 
	parameters.parameter_info_id
	parameter_groupings.group_id
from parameters 
join parameter_groupings on parameter_groupings.group_name = 'Enzymes'
or lower(parameters.parameter_name) like '%Alpha amylase%',
	or LOWER(parameters.paramater_name) like '%Aspartate aminotransferase%'
	or LOWER(parameters.paramater_name) like '%Alanine aminotransferase%'
	or LOWER(parameters.paramater_name) like '%Alkaline phosphate%';
	
	
	
	
	
#drop table parameter_group_linking;

#i think this is redundant, as im putting foreign keys into the paramaters and procedures.
#Could still keep it 
-- CREATE TABLE procedure_parameters (
    -- procedure_parameter_id INT AUTO_INCREMENT PRIMARY KEY,
    -- procedure_id INT NOT NULL,
    -- parameter_id VARCHAR(50) NOT NULL,
    -- FOREIGN KEY (procedure_id) REFERENCES procedures(procedure_id),
    -- FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id)
-- );


#last table

create TABLE phenotype_analyses(
	analysis_id VARCHAR(50) primary key,
	gene_id INT not null, -- loaded in from Genes
	parameter_id INT not null, -- matches parameters table pk
	mouse_strain VARCHAR(50) not null,
	life_stage VARCHAR (50) not null,
	pvalue DECIMAL(10,9), -- chnaged to decimal, better prescion
	
	foreign key (gene_id) references Genes(gene_id),
	foreign key (parameter_id) references parameters(parameter_id)
);
#core table could also be known as mouse table(	
#This table includes data from IMPC_cleaned_data (the phenotype data).
# Includes gene info, and the parameters tested.p value is included, this shows us the association score between the knockout gene and the phenotype
#Here the parameter_id is the one from the main IMPC data


-- Must create the 2 lookup tables to lload in data from gene table(pk) and parameters table(pk)
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
INTO table phenotype_analyses
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(@col, @col2, @col3, @col4, @col5, @col6, @col7, @col8)
SET
	analysis_id = @col1,
	gene_accession_id = @col2,
	gene_id = (
		select gene_id 
		from Genes 
		where gene_accession_id =@col2
		-- limit 1 -- had to do this because of gene accession duplicates
),
	parameter_id = (
		select parameter_id
		from parameters
		where parameterId = @col6
),
	mouse_strain= @col4,
	life_stage = @col5,
	pvalue = @col8;


drop table phenotype_analyses;


-- making a staging table 

CREATE TEMPORARY TABLE temp_phenotype (
    analysis_id VARCHAR(50),
    gene_accession_id varchar(50),
    gene_symbol varchar (50),
    mouse_strain VARCHAR(50),
    life_stage VARCHAR(50),
    parameterId varchar(50),
    parameter_name varchar(255),
    pvalue DOUBLE(10,9)
);

drop table temp_phenotype;

-- loading data into staging tbale
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
INTO TABLE temp_phenotype
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 rows
(analysis_id, gene_accession_id, gene_symbol, mouse_strain, 
life_stage, parameterId, parameter_name, @pvalue);

 -- insert with the joining tbale
-- ended up using a staging tabel as it allows sql to return mutltiple rows for gene acession matches
#the other method didnt 

INSERT INTO phenotype_analyses 
    (analysis_id, gene_id, parameter_id, mouse_strain, life_stage, pvalue)
SELECT 
    tp.analysis_id,
    g.gene_id,
    p.parameter_id,  -- The integer from parameters table
    tp.mouse_strain,
    tp.life_stage,
    tp.pvalue
FROM temp_phenotype tp
INNER JOIN Genes g 
    ON tp.gene_accession_id = g.gene_accession_id
INNER JOIN parameters p 
    ON tp.parameterId = p.parameterId;
-- -------------------------------

SELECT 'Checking Genes...' AS status, COUNT(*) FROM Genes;
SELECT 'Checking parameters...' AS status, COUNT(*) FROM parameters;

SELECT 'Records inserted:' AS status, COUNT(*) AS rows FROM phenotype_analyses;
