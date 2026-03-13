# Troubleshooting Guide

## Common Issues and Solutions

---

## BBDuk Step

### Issue 1: Module not found error

**Error:**
```
Lmod has detected the following error:
These module(s) or extension(s) exist but cannot be loaded as requested: "miniforge"
```

**Solution:**
```bash
# Check available versions
module spider miniforge

# Load the latest available
module load miniforge/25.3.0-3
```

**If miniforge not available:**
```bash
module load miniconda3/23.9.0-0
```

---

### Issue 2: BBDuk command not found

**Error:**
```
/var/spool/slurmd/job.../slurm_script: bbduk.sh: command not found
```

**Solution:**
1. Verify bbmap conda environment exists
2. Activate manually in script:
```bash
conda activate /scratch/user/YOUR_USERNAME/Conda/bbmap
which bbduk.sh
```

3. If not found, install bbmap:
```bash
conda install -c bioconda bbmap
```

---

### Issue 3: File not found warnings

**Error:**
```
Warning: R2 file not found for SG001_R1_001.fastq.gz, skipping...
```

**Solution:**
- Verify paired files are named consistently
- Check file naming: `SAMPLEID_S###_L###_R[1|2]_001.fastq.gz`
- Ensure both R1 and R2 exist before running

---

## QIIME2 Import Step

### Issue 4: Input format error

**Error:**
```
Error: Unrecognized arguments
```

**Possible causes:**
1. Incorrect CasavaOneEightSingleLanePerSampleDirFmt directory structure
2. Missing quality scores (.fastq not .fasta)

**Solution:**
- Verify directory contains only `.fastq.gz` files
- Check file naming matches: `SAMPLEID_S###_L###_R[1|2]_001.fastq.gz`

---

### Issue 5: Import job times out

**Error:**
```
TIMEOUT: Job exceeded time limit
```

**Solution:**
Increase time limit in script:
```bash
#SBATCH --time=2:00:00  # Increase from 1:00:00
```

---

## Cutadapt Step

### Issue 6: No sequences retained after cutadapt

**Error:**
```
demux-trimmed.qza is empty or has very few sequences
```

**Possible causes:**
1. `--p-discard-untrimmed` flag too strict
2. Primer sequences incorrect
3. Primers already removed by ACE

**Solution:**

**Option A: Remove `--p-discard-untrimmed` flag**
```bash
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences ${OUT_DIR}/demux-paired-end.qza \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --p-cores 4 \
  --o-trimmed-sequences ${OUT_DIR}/demux-trimmed.qza
# Remove the line: --p-discard-untrimmed
```

**Option B: Verify primer sequences**
Check your first few reads:
```bash
zcat bbduk/SG*_R1_001.fastq.gz | head -20
```

Look for sequences starting with: `GTGYCAGC...`

**Option C: Check with ACE if primers already removed**
Contact ACE facility - they may remove primers automatically.

---

### Issue 7: Forward vs reverse primer trimming asymmetry

**Observed:**
- Forward reads trimmed ~19bp
- Reverse reads not trimmed (or trimmed <5bp)

**Explanation:**
This is NORMAL! 
- Forward primer: Found at start of most R1 reads
- Reverse primer: Not always found in R2 (quality degradation)
- This is expected with variable-length reads

**Not a problem if:**
- Forward reads trimmed ~19bp (matches 515F length)
- Read counts similar before/after
- Quality scores maintained

---

## DADA2 Step

### Issue 8: DADA2 job times out

**Error:**
```
TIMEOUT: Job exceeded time limit
```

**Solution:**
Increase time and/or memory:
```bash
#SBATCH --time=3:00:00      # Increase from 2:00:00
#SBATCH --mem=32G           # Increase from 16G
#SBATCH --cpus-per-task=12  # Increase from 10
```

---

### Issue 9: Low merge rate

**Error/Observation:**
```
Very few reads successfully merged (< 50%)
```

**Possible causes:**
1. Truncation lengths set too short
2. Insufficient read overlap
3. Poor read quality

**Solution:**
Check your `denoising-stats.qzv` for merge percentages.

Adjust truncation if needed:
```bash
# If merge rate < 80%, try:
--p-trunc-len-f 250
--p-trunc-len-r 220  # Increase from 210
```

But verify quality first with `demux-trimmed.qzv`!

---

### Issue 10: Very few ASVs generated

**Observation:**
```
Only 5-10 ASVs in rep-seqs.qza (expected 50+)
```

**Possible causes:**
1. Contamination with single organism
2. Primers not completely removed
3. Sample issues

**Solution:**
1. Check rep-seqs visualization
2. Verify primer removal with cutadapt worked
3. Review sample collection/processing for issues

---

### Issue 11: High chimera rate (> 30%)

**Observation:**
```
Denoising stats show > 30% sequences removed as chimeras
```

**Possible causes:**
1. PCR artifacts
2. Mixed samples
3. Contamination

**Solution:**
Check `denoising-stats.qzv` - chimera rate of 10-20% is typical.

If very high, verify:
- Sample identity
- PCR amplification protocols
- Contamination during library prep

---

## Data Quality Issues

### Issue 12: Quality drops sharply after position 200bp (forward reads)

**Solution:**
Adjust truncation:
```bash
--p-trunc-len-f 200  # Instead of 250
```

But balance with merge overlap requirements!

---

### Issue 13: All samples have very different read counts

**Observation:**
```
Sample 1: 50,000 reads
Sample 2: 5,000 reads
Sample 3: 25,000 reads
```

**Possible causes:**
1. Unequal DNA input
2. Different sequencing performance per sample

**Solution:**
During diversity analysis, use rarefaction to normalize:
```bash
qiime diversity core-metrics-phylogenetic \
  --p-sampling-depth 5000  # Use lowest depth
```

---

## File/Path Issues

### Issue 14: "File not found" errors

**Error:**
```
Error: demux-paired-end.qza not found
```

**Solution:**
1. Verify previous step completed successfully
2. Check file paths in script match your setup
3. Confirm BASE_DIR and OUT_DIR variables

```bash
# Check if files exist
ls -lh /scratch/user/YOUR_USERNAME/J6784/last_analysis/results/
```

---

### Issue 15: Metadata file not found

**Error:**
```
Metadata file not found at [PATH]
```

**Solution:**
1. Verify metadata file exists and is readable
2. Check file path in script:
```bash
METADATA_FILE=${BASE_DIR}/data/rainforest-bark-metadata-FIXED.txt
# Verify this path is correct
```

3. Ensure metadata is TSV format (tab-separated)

---

## Getting Help

### Check logs

**Most recent job:**
```bash
# View all recent jobs
squeue -u YOUR_USERNAME

# View specific job output
cat slurm-JOBID.out
cat bbduk-JOBID.error

# Monitor running job
tail -f bbduk-JOBID.output
```

### Common commands

```bash
# List all jobs
squeue -u USERNAME

# Cancel job
scancel JOBID

# Get job info
scontrol show job JOBID

# Check account usage
alloc_report
```

### Contact

For Bunya HPC issues: https://portal.hpc.uq.edu.au/
For QIIME2 issues: https://forum.qiime2.org/

---

## Performance Tips

### Speed up DADA2 (most time-consuming step)

- Increase `--cpus-per-task` to 16-20
- Increase `--mem` to 32G
- May reduce overall runtime

### Monitor resource usage

During job execution:
```bash
# SSH to compute node and check usage
sstat -j JOBID.batch --format=AveCPU,AveRSS,MaxRSS
```

### Optimize for future runs

- If jobs timeout: Increase time limits
- If memory errors: Increase --mem
- If too slow: Increase --cpus-per-task
