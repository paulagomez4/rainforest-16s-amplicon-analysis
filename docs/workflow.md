# Rainforest 16S Amplicon Analysis - Detailed Workflow

## Overview

This document provides a detailed explanation of the 16S amplicon analysis pipeline for rainforest bark microbiome samples.

## Experimental Design

**Sequencing Details:**
- Platform: Illumina MiSeq
- Configuration: 2x300bp paired-end reads
- Region: 16S V3-V4 (515F/806wR primers)
- Samples: 3 rainforest tree species (1 biological replicate each)
- Facility: ACE (UQ)

**Note:** With only 3 samples, this analysis is exploratory. Consider collecting replicates for robust statistical comparisons.

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
```

### Expected Results

**Input:** Raw 2x300bp paired-end reads

**Output:** Quality-trimmed reads
- Forward (R1): ~291bp median
- Reverse (R2): ~289bp median
- **Expected retention:** 90-95% of sequences

### Quality Check

After running, verify:
```bash
ls -lh bbduk/SG*_R1_001.fastq.gz
# Files should be ~80-100MB each (depending on depth)
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
- All paired-end sequences
- Quality scores
- Sample metadata

### Quality Check

View visualization:
1. Download `demux-paired-end.qzv`
2. Upload to [QIIME2 View](https://view.qiime2.org/)
3. Check:
   - Sequence count per sample
   - Quality score distribution
   - Read length distribution

Expected metrics:
- All 3 samples present
- Forward reads: Median 291bp, Q35-Q20
- Reverse reads: Median 289bp, Q35-Q25

---

## Step 3: Primer Removal (Cutadapt)

### Purpose
Remove primer sequences that would interfere with denoising and taxonomic assignment.

### Script
`scripts/03-cutadapt.sh`

### Primers

**Forward (515F):** `GTGYCAGCMGCCGCGGTAA` (19bp)
- Positions: Start of R1
- Degeneracies: Y=C/T, M=A/C, R=A/G

**Reverse (806wR):** `CCGYCAATTYMTTTRAGTTT` (20bp)
- Positions: Start of R2
- Note: Not always found in R2 due to read length variation

### Parameters

```bash
--p-front-f GTGYCAGCMGCCGCGGTAA    # Remove 515F from R1
--p-front-r CCGYCAATTYMTTTRAGTTT   # Remove 806wR from R2
--p-cores 4                         # Parallel processing
```

### Expected Results

**Output:** `demux-trimmed.qza`

**Sequence lengths after trimming:**
- Forward: ~272bp median (19bp trimmed)
- Reverse: ~289bp median (primer not found in most)

This is expected! Reverse reads don't always contain the full primer sequence due to quality degradation at longer read positions.

### Quality Check

Compare visualizations:
```bash
# Compare:
demux-paired-end.qzv  (before cutadapt)
demux-trimmed.qzv     (after cutadapt)
```

Expected changes:
- Forward read length: 291bp → 272bp
- Reverse read length: Should remain ~289bp
- Quality scores: Similar or slightly improved

---

## Step 4: Denoising and ASV Generation (DADA2)

### Purpose
Denoise sequences and generate Amplicon Sequence Variants (ASVs):
- Remove sequencing errors
- Merge paired-end reads
- Identify chimeric sequences
- Generate final ASV table

### Script
`scripts/04-dada2.sh`

### Parameters

```bash
# Truncation (removes low-quality tails)
--p-trunc-len-f 250    # Keep 250bp of forward reads
--p-trunc-len-r 210    # Keep 210bp of reverse reads

# Trimming (remove primers - not needed, already done by cutadapt)
--p-trim-left-f 0
--p-trim-left-r 0

# Processing
--p-n-threads 10       # Parallel processing
--verbose              # Detailed output
```

### Truncation Rationale

Why these specific values?

**Forward reads (250bp):**
- Raw: 272bp median (after primer removal)
- Quality drops after position 250
- Removes low-quality tail
- Maintains good quality (Q~20-25)

**Reverse reads (210bp):**
- Raw: 289bp median
- Quality maintained longer than forward
- Truncated to 210bp to ensure sufficient overlap with forward
- DADA2 requires ≥16bp overlap to merge pairs

**Minimum overlap for merging:**
- 16bp overlap at truncation points
- Helps identify true sequences vs. errors

### DADA2 Workflow

1. **Learn error models** (per sample)
   - Models sequencing error rates
   - Used to distinguish errors from true variants

2. **Denoise** (error correction)
   - Infers sample composition
   - Removes systematic errors

3. **Merge** (pair-end assembly)
   - Combines R1 and R2 reads
   - Requires overlap verification
   - Final ASV length: ~250bp (V3-V4 region)

4. **Remove chimeras**
   - Identifies chimeric sequences
   - Typical removal rate: 5-15%

### Expected Results

**Outputs:**

1. **rep-seqs.qza** – Representative sequences
   - One sequence per ASV
   - FASTA format (stored in artifact)
   - Expected: 100-500 ASVs per sample

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
- **% Filtered:** Reads passing quality filter (should be >80%)
- **% Merged:** Successfully merged pairs (should be >90%)
- **% Non-chimeric:** After chimera removal (typically 85-95%)

Example (for 10,000 input reads per sample):
```
Input reads:        10,000
After filter:        9,500 (95%)
After merge:         9,200 (92% of input)
Non-chimeric:        8,800 (88% of input)
```

---

## Expected ASV Characteristics

### ASV Count
- Per sample: 50-500 ASVs (typical for environmental samples)
- Rainforest bark: Likely moderate diversity (50-200 ASVs)

### ASV Length
- Expected: ~252bp (V3-V4 region)
- Variation: 240-260bp (length heterogeneity in 16S)

### Read Depth
- Per sample: 5,000-50,000 final reads (depends on sequencing depth)

---

## Output Files

### Primary Artifacts (.qza)

- `rep-seqs.qza` – Representative ASV sequences
- `asv-table.qza` – ASV abundance matrix
- `denoising-stats.qza` – Denoising statistics

### Visualizations (.qzv)

- `demux-paired-end.qzv` – Raw sequence QC
- `demux-trimmed.qzv` – After primer removal
- `denoising-stats.qzv` – DADA2 QC

### Feature Data

- `sample-frequencies.qza` – Reads per sample
- `asv-frequencies.qza` – ASVs per sample
- `rep-seqs.qzv` – Sequence table

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
   - Compare species microbiomes
   - Identify indicator taxa

4. **Visualization**
   - Barplots
   - PCoA plots
   - Heatmaps

---

## Troubleshooting

See `docs/troubleshooting.md` for common issues and solutions.

---

## References

- DADA2: [https://www.nature.com/articles/nmeth.3869](https://www.nature.com/articles/nmeth.3869)
- QIIME2: [https://docs.qiime2.org/](https://docs.qiime2.org/)
- 515F/806R primers (EMP): [https://earthmicrobiome.org/protocols-and-standards/](https://earthmicrobiome.org/protocols-and-standards/)
