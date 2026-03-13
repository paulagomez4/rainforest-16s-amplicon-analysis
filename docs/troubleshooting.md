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

## DADA2 Step

### Issue 6: DADA2 job times out

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

### Issue 7: Low merge rate (< 80%)

**Error/Observation:**
```
Very few reads successfully merged (< 50% or < 80%)
```

**Possible causes:**
1. Truncation lengths too aggressive
2. Trim-left values incorrect
3. Primers not uniform across samples
4. Data quality issues

**Solution:**
Check `denoising-stats.qzv` for merge percentages.

**If merge rate < 50%:**
- Verify trim-left values match your primers
- Check that truncation lengths allow sufficient overlap
- Try increasing trunc-len-r by 10bp

**If merge rate 50-80%:**
- This is acceptable but could be improved
- Try: `--p-trunc-len-r 220` (instead of 210)

**If merge rate > 80%:**
- Excellent! Data quality is good ✅

---

### Issue 8: Very few ASVs generated

**Observation:**
```
Only 5-10 ASVs in rep-seqs.qza (expected 50+)
```

**Possible causes:**
1. Contamination with single organism
2. Incorrect trim-left values (data lost)
3. Sample issues

**Solution:**
1. Check rep-seqs visualization
2. Verify trim-left values match your primers (19, 20)
3. Review sample collection/processing for issues

---

### Issue 9: High chimera rate (> 30%)

**Observation:**
```
Denoising stats show > 30% sequences removed as chimeras
```

**Expected:** 10-25% is normal

**Possible causes:**
1. PCR artifacts
2. Mixed/contaminated samples
3. Poor merge overlap (low merge rate)

**Solution:**
Check `denoising-stats.qzv`:
- If merge rate < 80%: Adjust truncation lengths
- If merge rate > 80% but high chimeras: Sample contamination

Chimera rate of 10-22% is excellent ✅

---

## Primer Trimming Issues

### Issue 10: Trim-left values not working as expected

**Error:**
```
Trimmed sequences still contain primer sequences
```

**Possible causes:**
1. Primer sequences not at start of reads
2. Primers already removed by sequencing facility
3. Incorrect trim-left values for your primers

**Solution:**
```bash
# Check your first few reads
qiime tools export --input-path demux-paired-end.qza \
  --output-path demux-exported

# View first reads from one sample
zcat demux-exported/SG0649*/forward.fastq.gz | head -8

# Look at first line after sequence header
# Should start with: GTGYCAGCMGCCGCGGTAA (515F)
```

If primers are present:
- Confirm trim-left-f 19 and trim-left-r 20

If primers NOT present:
- Contact ACE sequencing facility
- Primers may have been pre-removed
- Use trim-left 0

---

## Data Quality Issues

### Issue 11: Quality drops sharply before position 210bp (reverse reads)

**Solution:**
Adjust truncation:
```bash
--p-trunc-len-r 180  # Reduce from 210
```

But verify with `demux-paired-end.qzv` first!

---

### Issue 12: All samples have very different read counts

**Observation:**
```
Sample 1: 50,000 reads
Sample 2: 5,000 reads
Sample 3: 25,000 reads
```

**Possible causes:**
1. Unequal DNA input
2. Different sequencing performance per sample
3. Different quality after filtering

**Solution:**
During diversity analysis, use rarefaction to normalize:
```bash
qiime diversity core-metrics-phylogenetic \
  --p-sampling-depth 5000  # Use lowest depth
```

---

## File/Path Issues

### Issue 13: "File not found" errors

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

### Issue 14: Metadata file not found

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
4. First column must be `sample-id`

---

## Workflow Comparison

### ❌ Old approach (NOT recommended)

Separate cutadapt step:
```bash
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences demux-paired-end.qza \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --p-discard-untrimmed \
  --o-trimmed-sequences demux-trimmed.qza
```

**Results:** 30-70% merge rate ❌

**Why it failed:** Over-trimming removed overlap needed for merging

---

### ✅ New approach (RECOMMENDED)

Direct trim-left in DADA2:
```bash
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-paired-end.qza \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 210 \
  --p-trim-left-f 19 \
  --p-trim-left-r 20 \
  ...
```

**Results:** 82-90% merge rate ✅

**Why it works:** Preserves overlap while removing primers

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

---

## Key Lessons Learned

1. **Direct trim-left > Separate cutadapt** for uniform primers
2. **Merge rate is critical** - expect >80% for good data
3. **Chimera rate 10-25%** is normal and healthy
4. **Monitor denoising-stats.qzv** to diagnose issues
5. **Preserve sequence overlap** for reliable merging
