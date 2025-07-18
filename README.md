# 🧬 EBOVar: Variant Calling Pipeline for EBOV Sequences

> **eboVar: A Bash Pipeline for EBOV Variant Profiling and analysis** 

---

## 📚 Table of Contents

- [Pipeline Overview](#-project-overview)
- [Script: eboVar.sh](#-script-ebovarsh)
- [Building the Apptainer Container](#-building-the-apptainer-container)
- [Running the Pipeline](#-running-the-pipeline)
- [Folder Structure](#-folder-structure)
- [Tools Used and Versions](#-tools-used-and-versions)
- [Expected Output](#-expected-output)
- [Gitignore and Tracking Output](#-gitignore-and-tracking-output)
- [Authors](#-authors)
- [License](#-license)

---

## 📖 Pipeline Overview

This pipeline presents a fully containerized, reproducible pipeline for processing *Ebola Virus (EBOV)* Illumina sequencing data — from raw reads to final variant calls. The pipeline is implemented in a bash script (`eboVar.sh`) and packaged inside an [Apptainer](https://apptainer.org) container to ensure portability and reproducibility across systems.

**Key features:**  
- Fully automated quality control, trimming, alignment, and variant calling  
- Conda-managed environment via `Miniforge3`  
- Apptainer containerization for reproducibility  
- Clean, organized output structure with logging for every sample  

---

## 🧰 Script: `eboVar.sh`

The `eboVar.sh` script performs the following pipeline steps:

1. **Quality Control** using `FastQC`  
2. **Trimming & Filtering** with `fastp`  
3. **Read Alignment** to EBOV reference genome using `BWA`  
4. **Variant Calling** with `bcftools`  

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

## ⚙ Building the Apptainer Container

1. Ensure you have [Apptainer](https://apptainer.org) installed on your system.  
   You can verify this by running:

```bash
which apptainer
```
Example output: `/usr/local/bin/apptainer`

2. Navigate to the `containers/` directory in your project:

```bash
cd containers
```

3. Build the container image from the definition file:

```bash
apptainer build ebovar.sif ebovar.def
```

## ▶ Running the Pipeline

Run the pipeline using the built container and bind your project directory to `/data` inside the container:

```bash
apptainer run --bind $(pwd):/data containers/ebovar.sif \
  -i ./data/rawreads \
  -r ./data/reference/ebov_ref.fa \
  -o ./results \
  -t 8
```

## 📁 Folder Structure

```
.
├── README.md                # This file
├── containers               # Apptainer container files
│   ├── ebovar.def           # Container definition file
│   ├── ebovar.sif           # Built Apptainer image
│   └── ebovar.yml           # Conda environment YAML file
├── data                     # Input data
│   ├── rawreads             # Raw FASTQ files (input reads)
│   └── reference            # Reference genome files and indexes
├── docs                     # Optional Documentation (e.g., images, reports)
├── results                  # Output directory
│   ├── bam                  # Sorted BAM alignment files and indexes
│   ├── logs                 # Pipeline run logs for each sample
│   ├── qc                   # FastQC output files
│   ├── trimmed              # Trimmed FASTQ files and fastp reports
│   └── vcf                  # Variant call files
└── scripts                  # Pipeline bash script
    └── eboVar.sh
```

## 🛠 Tools Used and Versions

- **FastQC**: `v.12.1`
- **Fastp**: `v1.0.1`
- **BWA**: `v0.7.19`
- **samtools**: `v1.22`
- **bcftools**: `v1.22`
- **mamba**: `v2.1.1` / **conda**: `v25.5.1` (via Miniforge)

## 📂 Expected Output

For each sample, the pipeline generates:

- **Quality Control:** FastQC reports (HTML + zip) in `results/qc/`
- **Trimmed Reads:** Filtered FASTQ files and fastp HTML/JSON reports in `results/trimmed/`
- **Alignments:** Sorted BAM files and BAM index files in `results/bam/`
- **Variants:** Compressed VCF files (`.vcf.gz`) and indexes in `results/vcf/`
- **Logs:** Detailed logs of pipeline steps in `results/logs/`

## 👥 Authors

Nelson, Precious, Salif, Elvis

## 📜 License

This pipeline is licensed under the MIT License.





