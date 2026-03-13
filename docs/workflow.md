# Rainforest 16S Amplicon Analysis - Detailed Workflow

## Overview

This document provides a detailed explanation of the simplified 3-step 16S amplicon analysis pipeline for rainforest bark microbiome samples.

## Experimental Design

**Sequencing Details:**
- Platform: Illumina MiSeq
- Configuration: 2x300bp paired-end reads
- Region: 16S V3-V4 (515F/806wR primers)
- Samples: 12 rainforest bark samples
- Facility: ACE (UQ)

---

## Pipeline Architecture

```
Raw FASTQ Files (300bp x 2)
        ↓
    BBDuk (Quality Trimming)
        ↓
    QIIME2 Import (demux-paired-end.qza)
        ↓
    DADA2 Denoising
    ├─ Remove primers (trim-left: 19bp, 20bp)
    ├─ Truncate reads (250bp, 210bp)
    ├─ Merge pairs
    └─ Remove chimeras
        ↓
    ASV Table + Representative Sequences
        ↓
    [Downstream: Taxonomy, Diversity]
```

---

## Step 1: Quality and Adapter Trimming (BBDuk)

### Purpose
Remove:
- Low-quality bases (Q < 10)
- Illumina sequencing adapters
- PhiX spike-in contamination
- Short/problematic reads

### Script
`scripts/01-bbduk.sh`

### Parameters

```bash
qtrim=rl           # Trim both left and right ends
trimq=10           # Quality threshold Q10 (90% accuracy)
minlength=50       # Discard reads <50bp
ktrim=r            # Trim kmers from right
k=23, mink=11      # Kmer matching
hdist=1            # 1 mismatch allowed
tpe, tbo           # Trim strategies
threads=10         # Parallel processing
```

### Expected Results

**Input:** Raw 2x300bp paired-end reads (~33.5k reads per sample)

**Output:** Quality-trimmed reads
- Forward (R1): ~291bp median
- Reverse (R2): ~289bp median
- **Expected retention:** 90-95% of sequences

### Quality Check

After running, verify:
```bash
ls -lh bbduk/SG*_R1_001.fastq.gz
# Files should be properly trimmed
```

---

## Step 2: QIIME2 Import

### Purpose
Convert raw FASTQ files to QIIME2 artifact format (.qza) for downstream analysis.

### Script
`scripts/02-import.sh`

### Parameters

```bash
--type 'SampleData[PairedEndSequencesWithQuality]'
--input-format CasavaOneEightSingleLanePerSampleDirFmt
```

### Expected Results

**Output:** `demux-paired-end.qza`

This artifact contains:
- All 12 samples
- Paired-end sequences
- Quality scores
- Sample metadata

### Quality Check

View visualization:
1. Download `demux-paired-end.qzv`
2. Upload to [QIIME2 View](https://view.qiime2.org/)
3. Check:
   - All 12 samples present
   - Sequence count per sample (13.5k - 66k)
   - Quality score distribution
   - Read length distribution (median ~290bp)

---

## Step 3: Denoising and ASV Generation (DADA2)

### Purpose
Denoise sequences, remove primers, merge pairs, and generate Amplicon Sequence Variants (ASVs):
- Remove sequencing errors
- Remove primer sequences (515F: 19bp, 806wR: 20bp)
- Merge paired-end reads
- Identify chimeric sequences
- Generate final ASV table

### Script
`scripts/03-dada2.sh`

### Why Direct trim-left (Not Separate Cutadapt)

**Previous approach (NOT recommended):**
- Separate cutadapt step
- Result: 30-70% merge rate ❌
- Issue: Over-trimmed sequences lost overlap for merging

**Current approach (RECOMMENDED):**
- Direct trim-left in DADA2
- Result: 82-90% merge rate ✅
- Advantage: Preserves overlap, simpler, more reliable

### Parameters

```bash
# Primer Removal via trim-left
--p-trim-left-f 19              # Remove 515F (19bp)
--p-trim-left-r 20              # Remove 806wR (20bp)

# Truncation (removes low-quality tails)
--p-trunc-len-f 250             # Keep 250bp of forward reads
--p-trunc-len-r 210             # Keep 210bp of reverse reads

# Processing
--p-n-threads 10                # Parallel processing
--verbose                       # Detailed output
```

### Truncation Rationale

**Forward reads (trim-left 19 → trunc 250):**
- Raw: 291bp
- After primer removal: 272bp
- After truncation: 250bp
- Quality: Good (Q~20-25 at position 250)

**Reverse reads (trim-left 20 → trunc 210):**
- Raw: 289bp
- After primer removal: 269bp
- After truncation: 210bp
- Quality: Maintained (Q~25-30)
- Purpose: Ensure sufficient overlap with forward reads

**Overlap for merging:**
- Minimum required: 16bp
- At positions 250bp (F) and 210bp (R): Adequate ✅

### DADA2 Workflow

1. **Learn error models** (per sample)
   - Models sequencing error rates
   - Used to distinguish errors from true variants

2. **Denoise** (error correction)
   - Infers sample composition
   - Removes systematic errors
   - Trim-left removes primer sequences

3. **Merge** (pair-end assembly)
   - Combines R1 and R2 reads
   - Requires overlap verification
   - Final ASV length: ~250bp (V3-V4 region)

4. **Remove chimeras**
   - Identifies chimeric sequences
   - Typical removal rate: 10-25%

### Expected Results

**Outputs:**

1. **rep-seqs.qza** – Representative sequences
   - One sequence per ASV
   - FASTA format (stored in artifact)
   - Expected: 100-500 ASVs total

2. **asv-table.qza** – ASV abundance table
   - Rows: ASVs
   - Columns: Samples
   - Values: Read counts per ASV per sample

3. **denoising-stats.qza** – Quality statistics
   - Input reads
   - Reads passing filter
   - Reads merged
   - Reads non-chimeric

### Quality Metrics to Check

After running, examine `denoising-stats.qzv`:

For each sample:
- **% Input:** Count of raw reads
- **% Filtered:** Reads passing quality filter
- **% Merged:** Successfully merged pairs (expect: >80% with direct trim-left)
- **% Non-chimeric:** After chimera removal (expect: 78-90%)

**Expected Results (Rainforest Project):**

```
Per-sample breakdown:
- Input: 13.5k - 66k reads
- Filtered: 85-91% retained
- Merged: 82-90% (good overlap!) ✅
- Non-chimeric: 78-90% (excellent data quality) ✅
```

---

## Output Files

### Primary Artifacts (.qza)

- `rep-seqs.qza` – Representative ASV sequences
- `asv-table.qza` – ASV abundance matrix
- `denoising-stats.qza` – Denoising statistics

### Visualizations (.qzv)

- `demux-paired-end.qzv` – Raw sequence QC
- `denoising-stats.qzv` – DADA2 QC
- `asv-table.qzv` – Feature table summary
- `rep-seqs.qzv` – Sequence table

### Feature Data

- `sample-frequencies.qza` – Reads per sample
- `asv-frequencies.qza` – ASVs per sample

---

## ASV Characteristics

### ASV Count
- Per sample: 50-300 ASVs typical
- Rainforest bark: Moderate diversity

### ASV Length
- Expected: ~250bp (V3-V4 region)
- Variation: 240-260bp (16S heterogeneity)

### Read Depth
- Per sample: 13.5k - 66k final reads
- Total: ~402k reads

---

## Next Steps (Downstream Analysis)

After successful DADA2 denoising:

1. **Taxonomy Assignment**
   - Classify ASVs against reference database (SILVA, Greengenes)
   - Command: `qiime feature-classifier classify-sklearn`

2. **Diversity Analysis**
   - Alpha diversity (within-sample)
   - Beta diversity (between-sample)
   - Rarefaction curves

3. **Differential Abundance**
   - Compare bark microbiomes
   - Identify indicator taxa

4. **Visualization**
   - Barplots
   - PCoA plots
   - Heatmaps

---

## References

- DADA2: [https://www.nature.com/articles/nmeth.3869](https://www.nature.com/articles/nmeth.3869)
- QIIME2: [https://docs.qiime2.org/](https://docs.qiime2.org/)
- 515F/806R primers (EMP): [https://earthmicrobiome.org/protocols-and-standards/](https://earthmicrobiome.org/protocols-and-standards/)
