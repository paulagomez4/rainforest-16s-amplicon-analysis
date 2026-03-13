#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --job-name=cutadapt
#SBATCH --time=2:00:00
#SBATCH --qos=normal
#SBATCH --partition=general
#SBATCH --account=a_barefoot
#SBATCH -o cutadapt-%j.output
#SBATCH -e cutadapt-%j.error

# Load conda env
module load miniforge/25.3.0-3
eval "$(conda shell.bash hook)"

# Activate qiime2 environment
conda activate qiime2-amplicon-2025.7

# Define paths
BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
OUT_DIR=${BASE_DIR}/results

# Remove 515F and 806wR primers
# 515F: GTGYCAGCMGCCGCGGTAA (forward)
# 806wR: CCGYCAATTYMTTTRAGTTT (reverse complement)
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences ${OUT_DIR}/demux-paired-end.qza \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --p-cores 4 \
  --o-trimmed-sequences ${OUT_DIR}/demux-trimmed.qza

# Visualize after trimming to verify
qiime demux summarize \
  --i-data ${OUT_DIR}/demux-trimmed.qza \
  --o-visualization ${OUT_DIR}/demux-trimmed.qzv

echo "Cutadapt trimming completed!"