create database if not EXISTS IMPC_phenotype_db
character set utf8mb4
collate utf8mb4_unicode_ci;


create table disease_ontology 
	Disease_info_id INT auto_increment primary key, 
	DO_disease_id VARCHAR(50) not null unique,
	DO_disease_name VARCHAR(200) not null ,
	OMIM_IDs VARCHAR (50) not null,	
	Mouse_MGI_ID VARCHAR (50) not null,
	association_score VARCHAR (50)not null,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	#Human disease from DO with OMIM






	create table Genes(
	gene_id INT auto_increment primary key,
	gene_accession_id VARCHAR(50) not null, 
	gene_symbol VARCHAR (100) not null
)

load data infile 'C:/Users/jeani/Desktop/DCDMGROUP10/CLEAN/IMPC_cleaned_data.csv'
into table Genes
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 lines;

show VARIABLES like 'secure_file_priv';



#Engine=InnoDB default CHARSET=utf8mb4 collate=utf8mb4_unicode_ci;

#one to many realationship
#Table is central references for all the mouse genes (MGI)
#Import data from DI_clean and IMPC_cleaned_data





create table Gene_disease_association (
	gene_disease_id INT auto_increment primary key,
	gene_id VARCHAR not null,
	DO_disease_id VARCHAR not null,
	foreign key (gene_id) references genes(gene_id)
	foreign key (Do_disease_id) references disease_ontology(DO_diease_id)
) engine = InnoDB default CHARSET=utf8mb4 collate=utf8mb4_unicode_ci;

#Links the disease to the associated gene
#import DI_clean_seperated

create table paramaters (
	paramter_description_id VARCHAR (50) primary key,
	parameter_name VARCHAR(500) NOT NULL,
    description TEXT,
    impc_parameter_orig_id INT,
    group_id INT,
    procedure_info_id INT,
    FOREIGN KEY (procedure_info_id) REFERENCES procedures (procedure_id),
) ENGINE=InnoDB;)



#this table helps to group the related paramters we want into one table
create table parameter_group(
	group_id INT AUTO increment primary key,
	group_name VARCHAR(100) not null unique,
	description TEXT,
) engine=InnoDB default CHARSET=utf8mb4 collate=utf8mb4_unicode_ci
	COMMENT='Hierarachial grouping of phenotypic paramaters'
	
insert into paramter_group (group_name,description) values

('weight ','Body weight, organ weights, and weight-normalized parameters' )
('Imaging paramters','X-ray, photograph, and other imaging-based measurements')
('Brain', 'Brain morphology, neural tube, and central nervous system parameters')

('Bone','Bone density, mineral content, skeletal structure parameters')
('Haematology','Complete blood count, blood chemistry, and circulatory parameters')
('Cardiovascular function', 'Heart function, ECG, blood pressure, and cardiac morphology')
('Vision', 'Eye morphology, retinal structure, lens parameters, and vision tests')


CREATE TABLE procedures (
    procedure_info_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT FALSE,
) ENGINE=InnoDB;

CREATE TABLE procedure_parameters (
    procedure_parameter_id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_id INT NOT NULL,
    parameter_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (procedure_id) REFERENCES procedures(procedure_id),
    FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id),
    UNIQUE KEY unique_procedure_parameter (procedure_id, parameter_id)
) ENGINE=InnoDB;



create table phenotype_analysis #core table could also be known as mouse table(
	analysis_id VARCHAR(50) primary key,
	gene_id INT not null,
	parameter_id INT not null,
	mouse_strain VARCHAR(50) not null,
	life_stage_id VARCHAR not null,
	is_significant BOOLEAN generated always as (pvalue <0.05) stored,
	foreign key (gene_id) references gene(gene_id),
	foreign key (parameter_id) references parameterS(parameter_id),
	foreign key (life_stage_id) references life_stage(life_stage_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	
