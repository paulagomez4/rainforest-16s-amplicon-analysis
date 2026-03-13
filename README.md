# Rainforest 16S Amplicon Analysis

16S amplicon sequencing analysis of bark samples from three rainforest tree species using QIIME2 on Bunya HPC (University of Queensland).

## 📋 Project Overview

**Sequencing Details:**
- Platform: Illumina MiSeq 2x300bp
- Target region: 16S V3-V4 (515F/806wR primers)
- Samples: 3 rainforest tree species × 1 sample per tree
- Sequencing facility: ACE (UQ)

**Analysis Pipeline:**
1. Quality and adapter trimming (BBDuk)
2. QIIME2 import and demultiplexing
3. Primer removal (cutadapt)
4. Denoising and ASV generation (DADA2)
5. Taxonomy assignment (downstream)
6. Diversity analysis (downstream)

## 🔧 Prerequisites

- Access to Bunya HPC (UQ)
- Conda/Miniforge installed
- QIIME2 environment: `qiime2-amplicon-2025.7`
- BBMap environment for BBDuk
- Raw sequencing data from ACE

## 📁 Repository Structure

```
rainforest-16s-amplicon-analysis/
├── README.md                          # This file
├── .gitignore                         # Git ignore rules
├── scripts/                           # All analysis scripts
│   ├── 01-bbduk.sh                   # Quality trimming
│   ├── 02-import.sh                  # QIIME2 import
│   ├── 03-cutadapt.sh                # Primer removal
│   ├── 04-dada2.sh                   # Denoising
│   └── README.md                     # Scripts documentation
├── config/                            # Configuration files
│   ├── parameters.txt                # All pipeline parameters
│   └── metadata-template.txt         # Sample metadata template
├���─ docs/                              # Documentation
│   ├── workflow.md                   # Detailed workflow guide
│   └── troubleshooting.md            # Common issues & solutions
└── data/                              # Data placeholder
    └── .gitkeep                       # Keep folder in git
```

## 🚀 Quick Start

### Step 1: Set up your working directory on Bunya

```bash
# Clone this repository
git clone https://github.com/paulagomez4/rainforest-16s-amplicon-analysis.git
cd rainforest-16s-amplicon-analysis

# Create your analysis directory structure
mkdir -p /scratch/user/YOUR_USERNAME/J6784/last_analysis/{data,results,bbduk}
```

### Step 2: Run the pipeline

```bash
# 1. Quality trimming
sbatch scripts/01-bbduk.sh

# 2. Import to QIIME2
sbatch scripts/02-import.sh

# 3. Remove primers
sbatch scripts/03-cutadapt.sh

# 4. Denoise with DADA2
sbatch scripts/04-dada2.sh
```

### Step 3: Monitor jobs

```bash
squeue -u YOUR_USERNAME
```

## 📊 Pipeline Parameters

See `config/parameters.txt` for detailed parameter descriptions.

**Key parameters (V3-V4, 2x300bp MiSeq):**
- BBDuk: `qtrim=rl trimq=10 minlength=50`
- Cutadapt: Remove 515F (GTGYCAGCMGCCGCGGTAA) and 806wR (CCGYCAATTYMTTTRAGTTT)
- DADA2: `trunc-len-f 250, trunc-len-r 210, trim-left-f 0, trim-left-r 0`

## 📝 Sample Metadata

Metadata file should be formatted as tab-separated values (TSV) with:
- Column 1: `sample-id` (must match fastq filenames)
- Additional columns: Any relevant metadata (species, location, etc.)

See `config/metadata-template.txt` for format.

## ⚠️ Important Notes

### File Paths
- **Update all paths** in scripts to match your Bunya username and account
- Default paths assume: `/scratch/user/YOUR_USERNAME/J6784/last_analysis/`

### HPC Configuration
- Account: `-a_barefoot` (update if different)
- Partition: `general`
- QOS: `normal`
- Adjust resource requests based on your needs

### Data Storage
- **Do NOT commit raw sequencing data** to this repository
- `.gitignore` excludes large files and data directories
- Store raw data separately on HPC scratch space

## 📖 Documentation

- **Workflow details:** See `docs/workflow.md`
- **Troubleshooting:** See `docs/troubleshooting.md`
- **Script documentation:** See `scripts/README.md`

## 📊 Expected Outputs

After running the full pipeline:
- `rep-seqs.qza` – Representative sequences (ASVs)
- `asv-table.qza` – Feature abundance table
- `denoising-stats.qza` – QC metrics
- `*.qzv` – Visualizations for QIIME2 View

## 🔗 References

- [QIIME2 Amplicon Tutorial](https://docs.qiime2.org/2025.1/tutorials/overview/)
- [BBDuk Documentation](https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbduk-guide/)
- [Cutadapt Documentation](https://cutadapt.readthedocs.io/)
- [DADA2 Paper](https://www.nature.com/articles/nmeth.3869)

## 👤 Author

Paula Gomez Alvarez
Southern Cross University (SCU)

## 📄 License

[Specify license - e.g., MIT, GPL-3.0]

---

**Last updated:** March 2026  
**QIIME2 version:** 2025.7  
**Bunya HPC:** University of Queensland
