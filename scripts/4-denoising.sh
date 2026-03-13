#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=16G
#SBATCH --job-name=denoising
#SBATCH --time=1:00:00
#SBATCH --qos=normal
#SBATCH --partition=general
#SBATCH --account=a_barefoot
#SBATCH -o dada2-%j.output
#SBATCH -e dada2-%j.error

# Load conda env
module load miniforge/25.3.0-3
eval "$(conda shell.bash hook)"

#Activate qiime2 environment
conda activate qiime2-amplicon-2025.7

#Define path
BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis/data
OUT_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis/results


qiime dada2 denoise-paired \
 --i-demultiplexed-seqs ${OUT_DIR}/demux-trimmed.qza \
 --p-trunc-len-f 250 \
 --p-trunc-len-r 210 \
 --p-trim-left-f 0 \
 --p-trim-left-r 0 \
 --p-n-threads 10 \
 --o-representative-sequences ${OUT_DIR}/rep-seqs-250-210-trimmed.qza\
 --o-table ${OUT_DIR}/asv-table-250-210-trimmed.qza \
 --o-denoising-stats ${OUT_DIR}/denoising-stats-250-210-trimmed.qza \
 --verbose

# qiime metadata tabulate \
# --m-input-file ${OUT_DIR}/denoising-stats-250-210-trimmed.qza \
# --o-visualization ${OUT_DIR}/denoising-stats-250-210-trimmed.qzv


#Summarise feature table
qiime feature-table summarize-plus \
  --i-table ${OUT_DIR}/asv-table-250-210-trimmed.qza \
  --m-metadata-file ${BASE_DIR}/rainforest-bark-metadata-FIXED.txt \
  --o-summary ${OUT_DIR}/asv-table-250-210-trimmed.qzv \
  --o-sample-frequencies ${OUT_DIR}/sample-frequencies-250-210-trimmed.qza \
  --o-feature-frequencies ${OUT_DIR}/asv-frequencies-250-210-trimmed.qza

#Tabulate representative sequences
qiime feature-table tabulate-seqs \
  --i-data ${OUT_DIR}/rep-seqs-250-210-trimmed.qza \
  --m-metadata-file ${OUT_DIR}/asv-frequencies-250-210-trimmed.qza \
  --o-visualization ${OUT_DIR}/rep-seqs-250-210-trimmed.qzv


