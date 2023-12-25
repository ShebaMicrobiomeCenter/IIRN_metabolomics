# Metagenomics pipeline using bioBakery

# Running kneaddata v0.10.0 on IIRN metagenome files (decontamination and trimming):
# The raw samples had each 4 files: 2 paired-end files in two lanes L3 & L4.
# Each sample was saved in a different directory inside PATH/TO/RAW, so we enter each subdirectoy and go over all the forward files per sample.
# i=${i##*/}; removes path
# i=${i%%_1.fq.gz}; removes extension
# Notice that ALL output directories already exist. So make sure you mkdir-ed everything beforehnad!

for dir in */; do cd $dir; for i in *_1.fq.gz; do i=${i##*/}; i=${i%%_1.fq.gz}; kneaddata -i /PATH/TO/RAW/${dir}${i}_1.fq.gz -i PATH/TO/RAW/${dir}${i}_2.fq.gz -o /PATH/TO/OUTPUT/kneaddata/main -db /PATH/TO/REFERENCE/DB/biobakery_workflows_databases/kneaddata_db/human_genome_bowtie2 --output-prefix ${i} -p 70 -t 10 --trimmomatic /PATH/TO/CONDA/miniconda3/envs/kneaddata-feb-2022/bin/; done; cd ..; done


# Summarizing kneaddata results:

kneaddata_read_count_table --input /PATH/TO/OUTPUT/kneaddata/main --output /PATH/TO/OUTPUT/kneaddata/merged/kneaddata_read_count_table.tsv

combining final fastq files in /PATH/TO/OUTPUT/kneaddata/main:
for f in *L3_paired_1.fastq; do f=${f%%_L3_paired_1.fastq}; for i in ${f}_L[34]_paired_[12].fastq; do cat ${i} >> ${f}.fastq; done; done


# Running MetaPhlAn 4.0.0: 
# We go over all the samples
cd /PATH/TO/OUTPUT/kneaddata/main
for f in *L3_paired_1.fastq
do

f=${f%%_L3_paired_1.fastq} # just getting the name of the sample

metaphlan /PATH/TO/OUTPUT/kneaddata/main/${f}.fastq --input_type fastq --output_file /PATH/TO/OUTPUT/metaphlan/main/${f}_taxonomic_profile.tsv --samout /PATH/TO/OUTPUT/main/${f}_bowtie2.sam --nproc 70 --no_map --tmp_dir /PATH/TO/OUTPUT/metaphlan/main --bowtie2db=/PATH/TO/REFERENCE/DB/biobakery_workflows_databases/metaphlan_db/v31 --index=mpa_vJan21_CHOCOPhlAnSGB_202103

done 


# merging metaphlan results in /PATH/TO/OUTPUT/metaphlan/main: (create a merged dir beforehand)
merge_metaphlan_tables.py *_taxonomic_profile.tsv > ../merged/metaphlan_taxonomic_profiles.tsv


# Running HUMAnN v3.6:
cd /PATH/TO/OUTPUT/kneaddata/main

for f in *L3_paired_1.fastq
do

f=${f%%_L3_paired_1.fastq}

humann -i /PATH/TO/OUTPUT/kneaddata/main/${f}.fastq -o /PATH/TO/OUTPUT/humann/main --o-log /PATH/TO/OUTPUT/humann/main/${f}.log --threads 70 --taxonomic-profile /PATH/TO/OUTPUT/metaphlan/main/${f}_taxonomic_profile.tsv --input-format fastq --remove-temp-output

done


# Post processing humann results. 
humann_join_tables --input /PATH/TO/OUPUT/humann/main/ --output /PATH/TO/OUTPUT/humann/merged/pathabundance.tsv --file_name pathabundance


humann_join_tables --input /PATH/TO/OUPUT/humann/main/ --output /PATH/TO/OUPUT/humann/merged/genefamilies.tsv --file_name genefamilies

humann_regroup_table --input /PATH/TO/OUPUT/humann/merged/genefamilies.tsv --output /PATH/TO/OUPUT/humann/merged/ecs.tsv --groups uniref90_level4ec


humann_renorm_table --input /PATH/TO/OUPUT/humann/merged/pathabundance.tsv --output /PATH/TO/OUPUT/humann/relab/pathabundance_relab.tsv --units relab --special n

humann_renorm_table --input /PATH/TO/OUPUT/humann/merged/genefamilies.tsv --output /PATH/TO/OUPUT/humann/relab/genefamilies_relab.tsv --units relab --special n

humann_renorm_table --input /PATH/TO/OUPUT/humann/merged/ecs.tsv --output /PATH/TO/OUPUT/humann/relab/ecs_relab.tsv --units relab --special n


humann_split_stratified_table -i /PATH/TO/OUPUT/humann/relab/pathabundance_relab.tsv -o /PATH/TO/OUPUT/humann/relab/

humann_split_stratified_table -i /PATH/TO/OUPUT/humann/relab/genefamilies_relab.tsv -o /PATH/TO/OUPUT/humann/relab/

humann_split_stratified_table -i /PATH/TO/OUPUT/humann/relab/ecs_relab.tsv -o /PATH/TO/OUPUT/humann/relab/

# We used the unstratified results in humann/relab for the functional profiles and metaphlan_taxonomic_profiles.tsv in metaphlan for the taxonomic profile. 
# For getting the species profile (i.e. just the species rank among the taxonomic profile) go to file creating_metaphlan_species_file_from_taxonomic_profile_for_IIRN.ipynb 
# You might want to change the sample names to make it less cumbersome for you. 

