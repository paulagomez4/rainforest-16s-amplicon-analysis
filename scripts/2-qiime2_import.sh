#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --job-name=qiime2-import
#SBATCH --time=1:00:00
#SBATCH --qos=normal
#SBATCH --partition=general
#SBATCH --account=a_barefoot
#SBATCH -o demux-%j.output
#SBATCH -e demux-%j.error

# Load conda env
module load miniforge/25.3.0-3
eval "$(conda shell.bash hook)"

#Activate qiime2 environment
conda activate qiime2-amplicon-2025.7

#Define paths
BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
OUT_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis/results

#Import data into qiime2
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ${BASE_DIR}/bbduk \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path ${OUT_DIR}/demux-paired-end.qza

#Visualise sequences
qiime demux summarize \
  --i-data ${OUT_DIR}/demux-paired-end.qza \
  --o-visualization ${OUT_DIR}/demux-paired-end.qzv
