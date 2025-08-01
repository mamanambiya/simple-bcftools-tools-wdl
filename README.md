# BCFtools Stats WDL Workflow

A simple WDL (Workflow Description Language) workflow for generating statistics from VCF/BCF files using bcftools stats.

## Overview

This workflow runs `bcftools stats` on VCF/BCF files to generate comprehensive statistics about variant calls, including:
- Sample statistics
- Variant counts by type (SNPs, indels, etc.)
- Quality score distributions
- Depth distributions
- Transition/transversion ratios
- And much more

## Requirements

- A WDL runner (e.g., Cromwell, miniwdl, Terra)
- Docker (the workflow uses containerized bcftools)

## Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `vcf_file` | File | Yes | - | Input VCF/BCF file |
| `vcf_index` | File | No | - | Index file for the VCF (e.g., .tbi or .csi) |
| `output_prefix` | String | No | "bcftools_stats" | Prefix for output files |
| `regions` | String | No | - | Genomic regions to include (e.g., "chr1:1000-2000") |
| `targets` | String | No | - | Target sites file or regions |
| `threads` | Int | No | 1 | Number of threads to use |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `stats_output` | File | Text file containing bcftools stats output |
| `plot_files` | File | Optional tar.gz archive containing plot files (if plot-vcfstats is available) |

## Usage

### 1. Using Cromwell

```bash
# Validate the workflow
java -jar cromwell.jar validate bcftools_stats.wdl

# Run the workflow
java -jar cromwell.jar run bcftools_stats.wdl --inputs inputs.json
```

### 2. Using miniwdl

```bash
# Validate the workflow
miniwdl check bcftools_stats.wdl

# Run the workflow
miniwdl run bcftools_stats.wdl -i inputs.json
```

### 3. Example inputs.json

```json
{
  "BcftoolsStats.vcf_file": "/path/to/your/input.vcf.gz",
  "BcftoolsStats.vcf_index": "/path/to/your/input.vcf.gz.tbi",
  "BcftoolsStats.output_prefix": "my_sample_stats",
  "BcftoolsStats.threads": 4
}
```

### 4. Running with specific regions

```json
{
  "BcftoolsStats.vcf_file": "/path/to/your/input.vcf.gz",
  "BcftoolsStats.vcf_index": "/path/to/your/input.vcf.gz.tbi",
  "BcftoolsStats.regions": "chr1:1000000-2000000",
  "BcftoolsStats.output_prefix": "chr1_region_stats",
  "BcftoolsStats.threads": 2
}
```

## Understanding the Output

The main output file (`*.stats.txt`) contains multiple sections:

1. **SN (Summary Numbers)**: Overall statistics like number of records, samples, SNPs, indels
2. **TSTV (Transitions/Transversions)**: Ratio statistics by sample
3. **SiS (Singleton Stats)**: Statistics for singletons
4. **AF (Allele Frequency)**: Distribution of allele frequencies
5. **QUAL (Quality)**: Distribution of variant quality scores
6. **DP (Depth)**: Distribution of read depths
7. **IDD (Indel Distribution)**: Distribution of indel lengths
8. **ST (Substitution Types)**: Counts of different substitution types
9. **GCsS (Genotype Counts per Sample)**: Per-sample genotype statistics

### Viewing the Results

```bash
# View summary statistics
grep "^SN" my_sample_stats.stats.txt

# View transitions/transversions ratio
grep "^TSTV" my_sample_stats.stats.txt

# Extract specific statistics
grep "^SN" my_sample_stats.stats.txt | grep "number of SNPs"
```

## Plotting Results

If the bcftools installation includes `plot-vcfstats`, the workflow will automatically generate plots. The plots will be packaged in a tar.gz file.

To extract and view the plots:

```bash
tar -xzf my_sample_stats_plots.tar.gz
cd my_sample_stats_plots/
# Open the HTML files in a web browser
```

## Docker Container

The workflow uses the BioContainers bcftools image:
- Image: `biocontainers/bcftools:v1.19-1-deb_cv1`
- This ensures reproducibility and eliminates the need to install bcftools locally

## Runtime Parameters

The workflow includes configurable runtime parameters:
- Memory: 4 GB (default)
- Disk: 50 GB (default)
- CPU: Matches the number of threads specified
- Preemptible instances: 3 attempts (for cost savings on cloud platforms)

## Troubleshooting

1. **Out of memory errors**: Increase the memory allocation by modifying the `memory_gb` parameter in the WDL
2. **Disk space errors**: Increase the `disk_size_gb` parameter for larger VCF files
3. **Missing index file**: Ensure your VCF is properly indexed using `bcftools index` or `tabix`

## Azure Deployment

This workflow includes support for running on Azure with containers stored in GitHub Container Registry. See [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md) for detailed instructions on:

- Building and pushing containers with GitHub Actions
- Configuring Azure Batch and Storage
- Running workflows with Cromwell on Azure
- Cost optimization strategies

### Quick Start for Azure

1. Fork this repository and update configuration:
   - Update `docker/Dockerfile` with your information
   - Update `bcftools_stats_azure.wdl` with your GitHub org/repo

2. Push to GitHub to trigger container build:
   ```bash
   git add .
   git commit -m "Configure for my Azure deployment"
   git push origin main
   ```

3. Configure Azure resources and run:
   ```bash
   # Update inputs_azure.json with your Azure storage URLs
   java -Dconfig.file=cromwell-azure.conf -jar cromwell.jar run bcftools_stats_azure.wdl --inputs inputs_azure.json
   ```

## License

This workflow is provided as-is for research and educational purposes.
