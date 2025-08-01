# Dockerfile for BCFtools with Azure and WDL compatibility
# Using official biocontainers/bcftools as base for faster builds
FROM biocontainers/bcftools:v1.19-1-deb_cv1

# Switch to root user for installations
USER root

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install additional dependencies for plot-vcfstats and Azure compatibility
RUN apt-get update && apt-get install -y \
    python3 \
    python3-matplotlib \
    python3-numpy \
    python3-pip \
    texlive-latex-base \
    texlive-latex-extra \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# plot-vcfstats should already be available in the biocontainers image
# but let's ensure it's in the PATH and executable
RUN if [ ! -f /usr/local/bin/plot-vcfstats ]; then \
        wget https://raw.githubusercontent.com/samtools/bcftools/develop/misc/plot-vcfstats -O /usr/local/bin/plot-vcfstats && \
        chmod +x /usr/local/bin/plot-vcfstats; \
    fi

# Set working directory
WORKDIR /data

# Add metadata labels
LABEL org.opencontainers.image.title="BCFtools for Azure"
LABEL org.opencontainers.image.description="BCFtools container optimized for Azure and WDL workflows"
LABEL org.opencontainers.image.version="1.19"
LABEL org.opencontainers.image.authors="mamanambiya"
LABEL org.opencontainers.image.source="https://github.com/mamanambiya/simple-bcftools-tools-wdl"

# Default command
CMD ["bcftools", "--version"]
