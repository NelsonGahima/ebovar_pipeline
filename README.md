# 🧬 EBOVar: Variant Calling Pipeline for EBOV Sequences

> **Capstone Project – Africa CDC Bioinformatics Fellowship**  
> **Group 1 | Module 15 | Date: July 10, 2025**

---

## 📚 Table of Contents

- [Project Overview](#-project-overview)
- [Script: eboVar.sh](#-script-ebovarsh)
- [Building the Container](#️-building-the-container)
- [Running the Pipeline](#-running-the-pipeline)
- [Project Structure](#-project-structure)
- [Tools Used](#-tools-used)
- [Expected Output](#-expected-output)
- [Gitignore and Tracking Output](#-gitignore-and-tracking-output)
- [Authors](#-authors)
- [License](#-license)

---

## 📖 Project Overview

This capstone project presents a fully containerized, reproducible pipeline for processing *Ebola Virus (EBOV)* Illumina sequencing data — from raw reads to final variant calls. The pipeline is implemented in a bash script (`eboVar.sh`) and packaged inside an [Apptainer](https://apptainer.org) container to ensure portability and reproducibility across systems.

Key features:  
- Fully automated read quality control, trimming, alignment, and variant calling  
- Conda-managed environment via `Miniforge3`  
- Apptainer containerization for reproducibility  
- Clean, organized output structure with logging for every sample  

---

## 🧰 Script: `eboVar.sh`

The script `eboVar.sh` is the core of the pipeline. It performs the following steps:

1. **Quality Control** – using `FastQC` on raw reads  
2. **Trimming & Filtering** – using `fastp`  
3. **Read Alignment** – with `BWA` to the EBOV reference genome  
4. **Variant Calling** – using `bcftools` for SNP/indel detection  

### 🖥️ Usage

```bash
apptainer run --bind $(pwd):/data containers/ebovar.sif \
  -i ./data/rawreads \
  -r ./data/reference/ebov_ref.fa \
  -t 8
```
### Options

| Option | Description                     | Required | Default |
|--------|---------------------------------|----------|---------|
| `-i`   | Input reads folder (raw FASTQ files) | Yes      | —       |
| `-r`   | Reference genome FASTA file     | Yes      | —       |
| `-o`   | Output folder for results       | No       | results |
| `-t`   | Number of threads               | No       | 8       |
| `-h`   | Show help and usage info        | No       | —       |

