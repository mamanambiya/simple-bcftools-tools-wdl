# Dockerfile for BCFtools with Azure and WDL compatibility
# Using official BioContainers bcftools from quay.io as base
# This image already includes bcftools, htslib, tabix, and plot-vcfstats
FROM quay.io/biocontainers/bcftools:1.19--h8b25389_1

# Set working directory
WORKDIR /data

# Add metadata labels
LABEL org.opencontainers.image.title="BCFtools for Azure"
LABEL org.opencontainers.image.description="BCFtools container with plot-vcfstats for Azure and WDL workflows"
LABEL org.opencontainers.image.version="1.19"
LABEL org.opencontainers.image.authors="mamanambiya"
LABEL org.opencontainers.image.source="https://github.com/mamanambiya/simple-bcftools-tools-wdl"
LABEL org.opencontainers.image.base="quay.io/biocontainers/bcftools:1.19--h8b25389_1"

# The BioContainers image already includes:
# - bcftools 1.19
# - htslib with S3/GCS support  
# - tabix
# - bgzip
# - plot-vcfstats
# - perl (required for plot-vcfstats)
# - All necessary dependencies

# Default command - show what's available
CMD ["sh", "-c", "echo 'BCFtools container ready!' && echo 'Available tools:' && echo '- bcftools $(bcftools --version | head -1)' && echo '- tabix $(tabix --version | head -1)' && echo '- plot-vcfstats available' && echo '- htsfile available'"]
