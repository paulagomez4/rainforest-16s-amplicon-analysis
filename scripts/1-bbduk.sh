#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=20G
#SBATCH --job-name=bbduk
#SBATCH --time=2:00:00
#SBATCH --qos=normal
#SBATCH --partition=general
#SBATCH --account=a_barefoot
#SBATCH -o bbduk-%j.output
#SBATCH -e bbduk-%j.error

# Load conda env
module load miniforge/25.3.0-3
eval "$(conda shell.bash hook)"

conda activate /scratch/user/paulagomezalvarez/Conda/bbmap

#Activate qiime 2 environment
#conda activate qiime2-amplicon-2025.7

BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
OUT_DIR=${BASE_DIR}/bbduk

cd ${BASE_DIR}/data

# Start the loop
for R1 in SG*_R1_001.fastq.gz; do
    # Skip if no files match
    [ -e "$R1" ] || continue
    
    R2="${R1/_R1_/_R2_}"
    
    # Check if R2 file exists
    if [ ! -f "$R2" ]; then
        echo "Warning: R2 file not found for $R1, skipping..."
        continue
    fi
    
    # Define outputs
    OUT1="${OUT_DIR}/$R1"
    OUT2="${OUT_DIR}/$R2"
    
    echo "Processing: $R1"
    
    bbduk.sh \
        in1="$R1" \
        in2="$R2" \
        out1="$OUT1" \
        out2="$OUT2" \
        ref=adapters,phix \
        ktrim=r k=23 mink=11 hdist=1 \
        qtrim=rl trimq=10 minlength=50 \
        tpe tbo \
        threads=10
    
    echo "Completed: $R1"
    echo "---"
done