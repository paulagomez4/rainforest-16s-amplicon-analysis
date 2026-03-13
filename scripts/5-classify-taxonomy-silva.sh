#!/bin/bash --login
#SBATCH --job-name=taxonomy-rainforest
#SBATCH --account=a_barefoot
#SBATCH --partition=general
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=04:00:00
#SBATCH -o taxonomy-%j.out
#SBATCH -e taxonomy-%j.err

# Load conda env
module load miniforge
eval "$(conda shell.bash hook)"

# Activate QIIME2
conda activate qiime2-amplicon-2025.7


BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
CLASS_DIR=/scratch/user/paulagomezalvarez/qiime2-classifiers
cpus=8
memory=128

qiime feature-classifier classify-sklearn \
  --i-classifier ${CLASS_DIR}/SILVA138.2_SSURef_NR99_weighted_classifier_V4-515f-806r_plant-surface.qza \
  --i-reads ${BASE_DIR}/results/rep-seqs-250-210-primers.qza \
  --p-reads-per-batch 3000 \
  --p-n-jobs 8 \
  --o-classification ${BASE_DIR}/results/taxonomy-silva-ps-V4-rainforest-250-210-primers.qza \
  --verbose

qiime metadata tabulate \
  --m-input-file ${BASE_DIR}/results/taxonomy-silva-ps-V4-rainforest-250-210-primers.qza \
  --o-visualization ${BASE_DIR}/results/taxonomy-silva-ps-V4-rainforest-250-210-primers.qzv


qiime feature-classifier classify-sklearn \
  --i-classifier ${CLASS_DIR}/SILVA138.2_SSURef_NR99_weighted_classifier_full-length_plant-surface.qza \
  --i-reads ${BASE_DIR}/results/rep-seqs-250-210-primers.qza \
  --p-reads-per-batch 3000 \
  --p-n-jobs 8 \
  --o-classification ${BASE_DIR}/results/taxonomy-silva-ps-full-rainforest-250-210-primers.qza \
  --verbose

qiime metadata tabulate \
  --m-input-file ${BASE_DIR}/results/taxonomy-silva-ps-full-rainforest-250-210-primers.qza \
  --o-visualization ${BASE_DIR}/results/taxonomy-silva-ps-full-rainforest-250-210-primers.qzv


# qiime feature-classifier classify-sklearn \
#  --i-classifier ${CLASS_DIR}/silva-138-99-nb-diverse-weighted-classifier.qza \
# --i-reads ${BASE_DIR}/results/rep-seqs-250-210-primers.qza \
#  --p-reads-per-batch 3000 \
#  --p-n-jobs 8 \
#  --o-classification ${BASE_DIR}/results/taxonomy-silva-diverse-rainforest-250-210-primers.qza \
#  --verbose


#qiime metadata tabulate \
#  --m-input-file ${BASE_DIR}/results/taxonomy-silva-diverse-rainforest-250-210-primers.qza \
#  --o-visualization ${BASE_DIR}/results/taxonomy-silva-diverse-rainforest-250-210-primers.qzv


