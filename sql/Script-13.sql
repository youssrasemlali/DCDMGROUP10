create database if not EXISTS IMPC_phenotype_db
character set utf8mb4
collate utf8mb4_unicode_ci;

use impc_phenotype_db;


create table Genes(
	gene_id INT auto_increment primary key,
	gene_accession_id VARCHAR(50) not null ,
	gene_symbol VARCHAR (100) not null
)
#Reasoning, gene_id is the surrogate pk
#gene_acession must be unique, each acession represents a gene
#gene symbol is not null as 
#central table for mouse genes

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_cleaned_data.csv'
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

show VARIABLES like 'secure_file_priv';

drop TABLE Genes

#Engine=InnoDB default CHARSET=utf8mb4 collate=utf8mb4_unicode_ci;

#one to many realationship
#Table is central references for all the mouse genes (MGI)
#Import data from DI_clean and IMPC_cleaned_data

create table Disease_ontology(
	Disease_info_id INT not null auto_increment primary key, 
	DO_disease_id VARCHAR(50) not null,
	DO_disease_name VARCHAR(500) not null,
	OMIM_IDs TEXT
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
	
select * from Disease_ontology

select * from disease_ontology where DO_disease_id ='DOID:14221';
#Realised that seperating the DI_clean data has produced duplicates 

TRUNCATE table Disease_ontology

DROP TABLE disease_ontology;
#Dropped the table to start again, put in a wrong column





#CREATE TABLE Omim_diseases (
    #omim_id INT AUTO_INCREMENT PRIMARY KEY,
    #omim_identifier VARCHAR(50) NOT NULL,
    #Disease_info_id INT,
    #FOREIGN KEY (disease_info_id) REFERENCES Disease_ontology(disease_info_id)
)

#Diseases can have more than one OMIM. This table reduces chance of disease name being repeated
#Allows for effective querying of OMID alone
#Multiple OMIM IDs are stored into seperate rows 
#Important for scalability 
#Omim_id is the pk we made and omim_identifier is the unique omim number in the disease.csv







create table Gene_disease_association (
	gene_disease_id INT auto_increment primary key,
	gene_id INT not null,
	Disease_info_id INT not null,
	foreign key (gene_id) references genes(gene_id),
	foreign key (Disease_info_id) references disease_ontology (Disease_info_id)
)

#Links the disease to the associated gene
#import DI_clean_seperated
#2 foreign keys for many-to-many relationship between genes and disease
#This is the joining table
#dont think i have to laod data here 

drop table Gene_disease_association




CREATE TABLE procedures (
    procedure_info_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(250) NOT NULL,
  	procedure_description TEXT,
    is_mandatory BOOLEAN DEFAULT false,
    parameter_id VARCHAR (250) not null
)
#paramter_id is the IMPC to link parameter (phenotypes) to the procedures

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
	is_mandatory = case when UPPER(@col3) = 'TRUE' then true else false END;

#false is a string, isnt automatically converted to an int
#code converts the true/false string into 1/0

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
INTO table procedures
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(@col1, @col2, @col3, @col4)
set
	parameter_id = @col4;


drop table procedures

#load datawont let me update to add additoal column from other csv
#Must make a temp table

#temp table
CREATE TABLE temp_parameters (
    parameter_id VARCHAR(50)
);

drop table temp_parameters

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
INTO TABLE temp_parameters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(col1, col2, col3, parameter_id);

update procedures 
join temp_parameters 
	on procedures.procedure_name = temp_parameters.col1
set procedures.parameter_id = temp_parameters.parameter_id;








create table parameters (
	parameter_info_id INT auto_increment primary key,
	impc_parameter_orig_id INT,
	parameter_name VARCHAR(200) NOT NULL,
    parameter_description TEXT,
    procedure_info_id INT,
    FOREIGN KEY (procedure_info_id) REFERENCES procedures (procedure_info_id)
)

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IMPC_parameter_description_clean.csv'
INTO table parameters
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(@col1, @col2, @col3, @col4)
SET
	impc_parameter_orig_id = @col1,
	parameter_name = @col2,
	parameter_description = @col3;
	
drop table parameters

SELECT impc_parameter_orig_id FROM parameters;	
	
	





#this table helps to group the related paramters we want into one table
#Defines our groups a
create table parameter_groupings(
	group_id INT AUTO_increment primary key,
	group_name VARCHAR(100) not null unique,
	group_description TEXT
)
	
insert into parameter_group (group_name,description) 

values
('weight ','Body weight, organ weights, and weight-normalized parameters' )
('Imaging parameters','parmeters with imaging-based measurements')
('Brain', 'Brain morphology and central nervous system parameters')

('Bone','Bone density, mineral content and skeletal structure parameters')
('Haematology','Complete blood count and blood chemistry paramters')
('Cardiovascular function', 'Heart function, ECG, blood pressure, and cardiac morphology')
('Vision', 'Eye morphology, retinal structure, lens parameters, and vision tests')

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
#



#i think this is redundant, as im putting foreign keys into the paramaters and procedures.
#Could still keep it 
CREATE TABLE procedure_parameters (
    procedure_parameter_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_info_id INT NOT NULL,
    parameter_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (procedure_info_id) REFERENCES procedures(procedure_info_id),
    FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id)
)



create table phenotype_analyses #core table could also be known as mouse table(
	analysis_id VARCHAR(50) auto_increment primary key,
	gene_accession_id (50) not null,
	gene_id INT not null,
	parameter_id INT not null,
	mouse_strain VARCHAR(50) not null,
	life_stage_id VARCHAR (50) not null,
	pvalue DOUBLE 
	foreign key (gene_id) references gene(gene_id),
	foreign key (parameter_info_id) references parameters(parameter_info_id),
)
	
#This table includes data from IMPC_cleaned_data (the phenotype data).
# Includes gene info, and the parameters tested.p value is included, this shows us the association score between the knockout gene and the phenotype