#!/bin/bash

# =============================================================
# Variant Calling Module: read processing -> variant calling
# Author: Group 1
# Date: July 10, 2025
# Version: 1.0
# Description:
#   This pipeline performs the following tasks:
#     1. FastQC on raw paired-end FASTQ reads
#     2. Fastp trimming and filtering
#     3. Trimmed reads alignment to the EBOV reference genome
#     4. Variant calling
# ================================================================

# -------------------------------
# ⚙️ Safety & strict error handling
# -------------------------------
set -euo pipefail

# -------------------------------
# 🎨 Terminal Colors
# -------------------------------
GREEN='\033[1;32m'   # Success
RED='\033[1;31m'     # Error
YELLOW='\033[1;33m'  # Warning / Info
BLUE='\033[1;36m'    # Info
NC='\033[0m'         # Reset

# -------------------------------
# Default Parameters
# -------------------------------
THREADS=8
READS_DIR=""
OUTDIR="./results"
REF_GEN=""

# -------------------------------
# �� Usage Function
# -------------------------------
usage() {
  echo
  echo -e "${BLUE}eboVar - EBOV Variant Calling Pipeline${NC}"
  echo
  echo -e "Options:"
  echo -e "  -i, --input     Path to folder with raw FASTQ files (required)"
  echo -e "  -o, --outdir    Results folder [default: results]"
  echo -e "  -r, --ref       reference genome FASTA file (required)"
  echo -e "  -t, --threads   Number of threads [default: 8]"
  echo -e "  -h, --help      Show this help message and exit"
  echo
  exit 1
}

# -------------------------------
# 🔍 Parse CLI Arguments
# -------------------------------
if [ $# -eq 0 ]; then
  echo
  echo -e "${RED}❌ No arguments provided.${NC}"
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      READS_DIR="$2"
      shift 2
      ;;
    -o|--outdir)
      OUTDIR="$2"
      shift 2
      ;;
    -r|--ref)
      REF_GEN="$2"
      shift 2
      ;;
    -t|--threads)
      THREADS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}❌ Unknown option: $1${NC}"
      usage
      ;;
  esac
done

# -------------------------------
# Validate required parameters
# -------------------------------
if [[ -z "$READS_DIR" ]]; then
  echo -e "${RED}ERROR: Input reads folder (-i) is required.${NC}" >&2
  exit 1
fi

if [[ -z "$REF_GEN" ]]; then
  echo -e "${RED}ERROR: Reference genome (-r) is required.${NC}" >&2
  exit 1
fi

if [[ ! -d "$READS_DIR" ]]; then
  echo -e "${RED}ERROR: Input reads directory '$READS_DIR' does not exist.${NC}" >&2
  exit 1
fi

if [[ ! -f "$REF_GEN" ]]; then
  echo -e "${RED}ERROR: Reference genome file '$REF_GEN' does not exist.${NC}" >&2
  exit 1
fi

# --------------------
# Check Required Tools
# --------------------
for tool in fastqc fastp bwa samtools bcftools; do
  if ! command -v $tool &> /dev/null; then
    echo -e "${RED}ERROR: Required tool '$tool' not found in PATH.${NC}" >&2
    exit 1
  fi
done

# -------------------------------
# 📁 Define Directory Structure
# -------------------------------
FASTQC_DIR="$OUTDIR/qc"
TRIMMED_DIR="$OUTDIR/trimmed"
ALIGNMENT_DIR="$OUTDIR/bam"
VARIANTS_DIR="$OUTDIR/vcf"
LOG_DIR="$OUTDIR/logs"

mkdir -p "$FASTQC_DIR" "$TRIMMED_DIR" "$ALIGNMENT_DIR" "$VARIANTS_DIR" "$LOG_DIR"

# --------------------
# Process each sample
# --------------------
# Check if any R1 FASTQ files exist
if ! ls "$READS_DIR"/*_1.fastq.gz 1> /dev/null 2>&1; then
  echo -e "${RED}ERROR: No FASTQ R1 files found in $READS_DIR${NC}" >&2
  exit 1
fi

# Loop over R1 FASTQ files directly
for r1 in "$READS_DIR"/*_1.fastq.gz; do
  # Extract sample basename by removing _1 and extension
  base=$(basename "$r1" _1.fastq.gz)

  LOG_FILE="$LOG_DIR/${base}.log"

  # ---------------------------------
  # Index reference genome if needed
  # ---------------------------------
  if [[ ! -f "${REF_GEN}.bwt" ]]; then
    echo -e "${BLUE}Indexing reference genome with bwa...${NC}"
    bwa index "$REF_GEN" 2>> "$LOG_FILE"
  fi

  if [[ ! -f "${REF_GEN}.fai" ]]; then
    echo -e "${BLUE}Indexing reference genome with samtools...${NC}"
    samtools faidx "$REF_GEN"
  fi

  echo -e "${BLUE}Processing sample: $base${NC}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting processing of sample $base" >> "$LOG_FILE"

  # Find paired R2 file
  r2="$READS_DIR/${base}_2.fastq.gz"
  if [[ ! -f "$r2" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Paired R2 FASTQ file for sample $base not found." >> "$LOG_FILE"
    echo -e "${RED}Paired R2 FASTQ file for sample $base not found. Skipping sample.${NC}"
    continue
  fi

  # Step 1: FastQC on raw reads
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running FastQC on raw reads" >> "$LOG_FILE"
  echo -e "${YELLOW}Running FastQC on raw reads...${NC}"
  fastqc -t "$THREADS" -o "$FASTQC_DIR" "$r1" "$r2" &>> "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FastQC completed successfully" >> "$LOG_FILE"
  echo -e "${GREEN}FastQC done.${NC}"

  # Step 2: Trim reads with fastp
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running fastp trimming" >> "$LOG_FILE"
  echo -e "${YELLOW}Trimming reads with fastp...${NC}"
  TRIMMED_r1="$TRIMMED_DIR/${base}_R1.trimmed.fastq.gz"
  TRIMMED_r2="$TRIMMED_DIR/${base}_R2.trimmed.fastq.gz"
  fastp -i "$r1" -I "$r2" \
    -o "$TRIMMED_r1" -O "$TRIMMED_r2" \
    -w "$THREADS" \
    -h "$TRIMMED_DIR/${base}_fastp.html" \
    -j "$TRIMMED_DIR/${base}_fastp.json" \
    &>> "$LOG_FILE"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] fastp trimming completed successfully" >> "$LOG_FILE"
  echo -e "${GREEN}Fastp trimming done.${NC}"

  # Step 3: Align trimmed reads with bwa mem tool
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running bwa mem alignment" >> "$LOG_FILE"
  echo -e "${YELLOW}Aligning reads with bwa mem...${NC}"
  SORTED_BAM_FILE="$ALIGNMENT_DIR/${base}.sorted.bam"

  bwa mem -t "$THREADS" "$REF_GEN" "$TRIMMED_r1" "$TRIMMED_r2" 2>> "$LOG_FILE" | \
  samtools view -b -@ "$THREADS" - | \
  samtools sort -@ "$THREADS" -o "$SORTED_BAM_FILE" &>> "$LOG_FILE"

  # Index the sorted BAM file
  samtools index "$SORTED_BAM_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Alignment and BAM sorting/indexing successful" >> "$LOG_FILE"
  echo -e "${GREEN}Alignment done.${NC}"

  # Step 4: Variant calling with bcftools
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running bcftools mpileup and call" >> "$LOG_FILE"
  echo -e "${YELLOW}Calling variants with bcftools...${NC}"
  COMPRESSED_VCF="$VARIANTS_DIR/${base}.vcf.gz"
  
  bcftools mpileup -f "$REF_GEN" "$SORTED_BAM_FILE" 2>> "$LOG_FILE" | \
  bcftools call --ploidy 1 -mv -Oz -o "$COMPRESSED_VCF" 2>> "$LOG_FILE"

  bcftools index "$COMPRESSED_VCF" 2>> "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Variant calling successful" >> "$LOG_FILE"
  echo -e "${GREEN}Variant calling done.${NC}"


  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished processing sample $base successfully" >> "$LOG_FILE"
  echo -e "${GREEN}✓ Sample $base processing complete.${NC}"
  echo
done

echo -e "${GREEN}✅ All samples processed.${NC}"