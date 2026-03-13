# Pipeline Scripts

All scripts are designed to run on Bunya HPC with SLURM job scheduling.

## Script Overview

### 1. `01-bbduk.sh` - Quality and Adapter Trimming

**Purpose:** Remove low-quality bases, adapters, and PhiX contamination

**Input:** Raw paired-end fastq.gz files from ACE sequencing

**Output:** Quality-trimmed fastq.gz files

**Key parameters:**
- `qtrim=rl` – Quality trim both ends
- `trimq=10` – Trim to Q10
- `minlength=50` – Discard reads <50bp
- `threads=10` – Use 10 CPU cores

**Run:**
```bash
sbatch 01-bbduk.sh
```

---

### 2. `02-import.sh` - QIIME2 Import

**Purpose:** Convert raw fastq files to QIIME2 artifact format

**Input:** BBDuk-trimmed fastq.gz files (Casava 1.8 format)

**Output:** `demux-paired-end.qza` (QIIME2 artifact)

**Key parameters:**
- Format: `CasavaOneEightSingleLanePerSampleDirFmt`
- Type: `SampleData[PairedEndSequencesWithQuality]`

**Run:**
```bash
sbatch 02-import.sh
```

---

### 3. `03-dada2.sh` - Denoising and ASV Generation

**Purpose:** Denoise sequences, remove primers, merge pairs, and generate Amplicon Sequence Variants (ASVs)

**Input:** `demux-paired-end.qza`

**Outputs:**
- `rep-seqs.qza` – Representative sequences
- `asv-table.qza` – ASV abundance table
- `denoising-stats.qza` – QC statistics

**Key parameters:**
- `trunc-len-f 250` – Truncate forward reads to 250bp
- `trunc-len-r 210` – Truncate reverse reads to 210bp
- `trim-left-f 19` – Remove 515F primer (19bp)
- `trim-left-r 20` – Remove 806wR primer (20bp)
- `n-threads 10` – Use 10 CPU cores

**Why this approach?**
- Direct primer trimming with `trim-left` parameters
- Works well with uniform primer sequences (ACE)
- No need for separate cutadapt step
- Maintains proper sequence overlap for merging

**Run:**
```bash
sbatch 03-dada2.sh
```

---

## Customization

### Updating Paths

Each script contains:
```bash
BASE_DIR=/scratch/user/paulagomezalvarez/J6784/last_analysis
OUT_DIR=${BASE_DIR}/results
```

**Update these to match your Bunya username and project directory.**

### Adjusting Resources

Modify SLURM headers for different needs:
```bash
#SBATCH --cpus-per-task=4      # CPU cores
#SBATCH --mem=8G               # Memory
#SBATCH --time=1:00:00         # Time limit
```

### Monitoring

Check job status:
```bash
squeue -u YOUR_USERNAME
```

View output:
```bash
tail -f bbduk-JOBID.output
cat bbduk-JOBID.error
```

---

## Troubleshooting

See `../docs/troubleshooting.md` for common issues.

---

## Notes

- Removed cutadapt as separate step (integrated into DADA2 via trim-left)
- Simpler 3-step workflow improves reliability
- Better merge rates (82-90% vs cutadapt: 30-70%)
