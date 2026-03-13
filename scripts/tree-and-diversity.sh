#!/bin/bash --login
#SBATCH --job-name=diversity
#SBATCH --account=a_barefoot
#SBATCH --partition=general
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --time=02:00:00
#SBATCH -o diversity-%j.out
#SBATCH -e diversity-%j.err

# Load conda env
module load miniforge
eval "$(conda shell.bash hook)"

# Activate QIIME2
conda activate qiime2-amplicon-2025.7


BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
# mkdir -p ${BASE_DIR}/results/tree

# Tree
# qiime phylogeny align-to-tree-mafft-fasttree \
#  --i-sequences ${BASE_DIR}/results/rep-seqs-250-210-silva-filtered.qza \
#  --o-alignment ${BASE_DIR}/results/tree/aligned-rep-seqs-silva-filtered.qza \
#  --o-masked-alignment ${BASE_DIR}/results/tree/masked-aligned-rep-seqs-silva-filtered.qza \
#  --o-tree ${BASE_DIR}/results/tree/unrooted-tree-silva-filtered.qza \
#  --o-rooted-tree ${BASE_DIR}/results/tree/rooted-tree-silva-filtered.qza

# Core Diversity Script
# qiime diversity core-metrics-phylogenetic \
#  --i-phylogeny ${BASE_DIR}/results/tree/rooted-tree-silva-filtered.qza \
#  --i-table ${BASE_DIR}/results/asv-table-250-210-silva-filtered.qza \
#  --p-sampling-depth 2400 \
#  --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
#  --output-dir ${BASE_DIR}/results/core-metrics-results


#OPTION 2 because it is crashing

# 1. Create the output directory manually since the wrapper won't do it
# mkdir -p ${BASE_DIR}/results/core-metrics-results

# 2. Rarefy the table (This is what --p-sampling-depth does)
#qiime feature-table rarefy \
#  --i-table ${BASE_DIR}/results/asv-table-250-210-silva-filtered.qza \
#  --p-sampling-depth 2400 \
#  --o-rarefied-table ${BASE_DIR}/results/core-metrics-results/rarefied_table.qza

# 3. Calculate Alpha Diversity (Skipping the broken 'sobs')
# This creates the 'observed_features_vector.qza' your script needs
#qiime diversity alpha \
#  --i-table ${BASE_DIR}/results/core-metrics-results/rarefied_table.qza \
#  --p-metric observed_features \
#  --o-alpha-diversity ${BASE_DIR}/results/core-metrics-results/observed_features_vector.qza

#qiime diversity alpha \
#  --i-table ${BASE_DIR}/results/core-metrics-results/rarefied_table.qza \
#  --p-metric shannon \
#  --o-alpha-diversity ${BASE_DIR}/results/core-metrics-results/shannon_vector.qza

#qiime diversity alpha \
#  --i-table ${BASE_DIR}/results/core-metrics-results/rarefied_table.qza \
#  --p-metric pielou_e \
#  --o-alpha-diversity ${BASE_DIR}/results/core-metrics-results/evenness_vector.qza


## Alpha Significance (Richness and Diversity)
#qiime diversity alpha-group-significance \
#  --i-alpha-diversity ${BASE_DIR}/results/core-metrics-results/observed_features_vector.qza \
#  --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
#  --o-visualization ${BASE_DIR}/results/core-metrics-results/observed_features-significance.qzv

#qiime diversity alpha-group-significance \
#  --i-alpha-diversity ${BASE_DIR}/results/core-metrics-results/evenness_vector.qza \
#  --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
#  --o-visualization ${BASE_DIR}/results/core-metrics-results/evenness-group-significance.qzv


# 4. Calculate Beta Diversity (Unweighted UniFrac)
# This creates the 'distance_matrix.qza' your script needs
#qiime diversity beta-phylogenetic \
#  --i-table ${BASE_DIR}/results/core-metrics-results/rarefied_table.qza \
#  --i-phylogeny ${BASE_DIR}/results/tree/rooted-tree-silva-filtered.qza \
#  --p-metric unweighted_unifrac \
#  --o-distance-matrix ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_distance_matrix.qza


## Beta Significance (PERMANOVA)
# This tests if different tree species have different microbial communities
#qiime diversity beta-group-significance \
#  --i-distance-matrix ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
#  --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
#  --m-metadata-column species \
#  --o-visualization ${BASE_DIR}/results/core-metrics-results/unweighted-unifrac-significance-species.qzv \
#  --p-pairwise

# This tests Bark vs Soil
#qiime diversity beta-group-significance \
#  --i-distance-matrix ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
#   --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
#  --m-metadata-column sample-type \
#  --o-visualization ${BASE_DIR}/results/core-metrics-results/unweighted-unifrac-significance-sample-type.qzv \
#  --p-pairwise

# Calculate PCoA
qiime diversity pcoa \
  --i-distance-matrix ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --o-pcoa ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_pcoa_results.qza

# Create Emperor Plot
qiime emperor plot \
  --i-pcoa ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file ${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt \
  --o-visualization ${BASE_DIR}/results/core-metrics-results/unweighted_unifrac_emperor.qzv
