# BCFtools WDL Workflow for Azure - Project Summary

This project provides a complete solution for running bcftools statistics workflows on Azure using WDL (Workflow Description Language), GitHub Actions for CI/CD, and GitHub Container Registry for container storage.

## 📁 Project Structure

### Core Workflow Files
- `bcftools_stats.wdl` - Simple workflow for generating VCF statistics
- `bcftools_extended.wdl` - Extended workflow with multiple bcftools commands
- `bcftools_stats_azure.wdl` - Azure-optimized workflow using GitHub Container Registry

### Input Configuration
- `inputs.json` - Example inputs for simple workflow
- `inputs_extended.json` - Example inputs for extended workflow
- `inputs_azure.json` - Azure-specific inputs with storage URLs

### Docker Configuration
- `docker/Dockerfile` - Multi-platform bcftools container with Azure optimizations
- `docker/test_local.sh` - Local testing script for the container

### GitHub Actions CI/CD
- `.github/workflows/build-docker.yml` - Builds and pushes container to GitHub Container Registry
- `.github/workflows/test-wdl.yml` - Validates WDL syntax and tests workflows

### Documentation
- `README.md` - Main documentation with usage instructions
- `AZURE_DEPLOYMENT.md` - Comprehensive Azure deployment guide
- `PROJECT_SUMMARY.md` - This file

### Utilities
- `validate_workflow.sh` - Script to validate WDL syntax locally
- `.gitignore` - Git ignore patterns for WDL projects

## 🚀 Quick Start

1. **Fork this repository** and update configuration:
   ```bash
   # Update in docker/Dockerfile
   LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
   
   # Update in bcftools_stats_azure.wdl
   String github_org = "YOUR_GITHUB_ORG"
   String github_repo = "YOUR_REPO_NAME"
   ```

2. **Push to trigger container build**:
   ```bash
   git add .
   git commit -m "Configure for my deployment"
   git push origin main
   ```

3. **Configure Azure resources** (see AZURE_DEPLOYMENT.md for details)

4. **Run the workflow**:
   ```bash
   java -Dconfig.file=cromwell-azure.conf \
     -jar cromwell.jar \
     run bcftools_stats_azure.wdl \
     --inputs inputs_azure.json
   ```

## 🔑 Key Features

### Container Management
- **Automated builds** with GitHub Actions on every push
- **Multi-platform support** (linux/amd64, linux/arm64)
- **Version tagging** (latest, branch names, semantic versions)
- **Public or private** container registry options

### Azure Integration
- **Azure Batch** support for scalable compute
- **Azure Storage** integration for input/output files
- **Cost optimization** with low-priority VMs and preemptible instances
- **Security** best practices with managed identities and Key Vault

### Workflow Features
- **bcftools stats** for comprehensive variant statistics
- **Optional plotting** with plot-vcfstats
- **Configurable resources** (CPU, memory, disk)
- **Error handling** and retry logic
- **Region and target filtering** support

## 📊 Workflow Outputs

1. **Statistics file** (`*.stats.txt`) - Comprehensive bcftools stats output
2. **Summary file** (`*.summary.txt`) - Key statistics summary
3. **Plot archive** (`*_plots.tar.gz`) - Optional visualization plots

## 🔧 Customization

### Adding New bcftools Commands
Edit `bcftools_extended.wdl` to add new tasks:
```wdl
task RunBcftoolsNewCommand {
    input {
        File vcf_file
        # Add your parameters
    }
    command <<<
        bcftools your-command ~{vcf_file}
    >>>
}
```

### Modifying Container
Edit `docker/Dockerfile` to add new tools or dependencies:
```dockerfile
RUN apt-get update && apt-get install -y \
    your-new-package
```

### Adjusting Azure Resources
Modify runtime parameters in the WDL:
```wdl
runtime {
    memory: "16 GB"  # Increase for large files
    cpu: 8           # More cores for parallel processing
}
```

## 📝 Next Steps

1. **Test locally** with miniwdl or Cromwell
2. **Set up Azure resources** following AZURE_DEPLOYMENT.md
3. **Monitor costs** and optimize resource usage
4. **Scale up** for production workloads

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation: `./validate_workflow.sh`
5. Submit a pull request

## 📄 License

This workflow is provided as-is for research and educational purposes.
