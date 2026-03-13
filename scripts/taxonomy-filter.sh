#!/bin/bash --login
#SBATCH --job-name=taxonomy-filter
#SBATCH --account=a_barefoot
#SBATCH --partition=general
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH -o taxonomy-%j.out
#SBATCH -e taxonomy-%j.err

# Load conda env
module load miniforge
eval "$(conda shell.bash hook)"

# Activate QIIME2
conda activate qiime2-amplicon-2025.7


BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis

# Filter out mitochondria and chloroplast from your table
qiime taxa filter-table \
    --i-table ${BASE_DIR}/results/asv-table-250-210-primers.qza \
    --i-taxonomy ${BASE_DIR}/results/taxonomy-silva-ps-rainforest-250-210-primers.qza \
    --p-exclude mitochondria,chloroplast,Eukaryota \
    --o-filtered-table ${BASE_DIR}/results/asv-table-250-210-silva-filtered.qza

# Filter the sequences to match
qiime taxa filter-seqs \
    --i-sequences ${BASE_DIR}/results/rep-seqs-250-210-primers.qza \
    --i-taxonomy ${BASE_DIR}/results/taxonomy-silva-ps-rainforest-250-210-primers.qza \
    --p-exclude mitochondria,chloroplast,Eukaryota \
    --o-filtered-sequences ${BASE_DIR}/results/rep-seqs-250-210-silva-filtered.qza

# Check before and after
# BEFORE FILTERING:"
qiime feature-table summarize \
    --i-table ${BASE_DIR}/results/asv-table-250-210-primers.qza \
    --o-visualization ${BASE_DIR}/results/asv-table-summary-before.qzv \
    --m-sample-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt

echo "AFTER FILTERING:"
qiime feature-table summarize \
    --i-table ${BASE_DIR}/results/asv-table-250-210-silva-filtered.qza \
    --o-visualization ${BASE_DIR}/results/asv-table-summary-after.qzv \
    --m-sample-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt

