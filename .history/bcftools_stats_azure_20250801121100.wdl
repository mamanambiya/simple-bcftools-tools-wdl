version 1.0

# Azure-optimized WDL workflow using GitHub Container Registry

workflow BcftoolsStatsAzure {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix = "bcftools_stats"
        String? regions
        String? targets
        Int? threads = 1
        
        # Azure-specific parameters
        String? azure_storage_account
        String? azure_container_name
        
        # Container registry settings
        String github_org = "mamanambiya"
        String github_repo = "simple-bcftools-tools-wdl"
        String container_tag = "latest"
    }
    
    String docker_image = "ghcr.io/${github_org}/${github_repo}/bcftools-azure:${container_tag}"

    call RunBcftoolsStatsAzure {
        input:
            vcf_file = vcf_file,
            vcf_index = vcf_index,
            output_prefix = output_prefix,
            regions = regions,
            targets = targets,
            threads = threads,
            docker_image = docker_image,
            azure_storage_account = azure_storage_account,
            azure_container_name = azure_container_name
    }

    output {
        File stats_output = RunBcftoolsStatsAzure.stats_output
        File? plot_files = RunBcftoolsStatsAzure.plot_files
        File stats_summary = RunBcftoolsStatsAzure.stats_summary
    }

    meta {
        description: "Azure-optimized bcftools stats workflow using GitHub Container Registry"
        author: "WDL Workflow for Azure"
    }
}

task RunBcftoolsStatsAzure {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix
        String? regions
        String? targets
        Int threads
        String docker_image
        String? azure_storage_account
        String? azure_container_name
        
        # Azure Batch runtime parameters
        Int memory_gb = 8
        Int disk_size_gb = 100
        Int cpu = threads
        Int max_retries = 2
        Int preemptible_tries = 3
    }

    String stats_output_name = "${output_prefix}.stats.txt"
    String stats_summary_name = "${output_prefix}.summary.txt"
    String plot_output_dir = "${output_prefix}_plots"

    command <<<
        set -euo pipefail
        
        # Display system information
        echo "Running on Azure with bcftools from GitHub Container Registry"
        echo "Container: ~{docker_image}"
        echo "CPU cores: $(nproc)"
        echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
        echo "Disk space: $(df -h | grep -E '^/dev/root|^overlay' | awk '{print $4}')"
        
        # Show bcftools version
        bcftools --version
        
        # Create output directory for plots
        mkdir -p ~{plot_output_dir}
        
        # Run bcftools stats
        echo "Running bcftools stats..."
        bcftools stats \
            ~{"--regions " + regions} \
            ~{"--targets " + targets} \
            --threads ~{threads} \
            ~{vcf_file} \
            > ~{stats_output_name}
        
        # Generate summary statistics
        echo "Generating summary..."
        {
            echo "BCFtools Stats Summary"
            echo "====================="
            echo ""
            echo "Input file: ~{vcf_file}"
            echo "Date: $(date)"
            echo ""
            echo "Key Statistics:"
            echo "---------------"
            grep "^SN" ~{stats_output_name} | head -20
        } > ~{stats_summary_name}
        
        # Generate plots if plot-vcfstats is available
        if command -v plot-vcfstats &> /dev/null; then
            echo "Generating plots..."
            plot-vcfstats -p ~{plot_output_dir}/ ~{stats_output_name} || {
                echo "Warning: plot-vcfstats failed, continuing without plots"
            }
            
            # Create a tar of plot files if they were generated
            if [ -d "~{plot_output_dir}" ] && [ "$(ls -A ~{plot_output_dir})" ]; then
                tar -czf ~{plot_output_dir}.tar.gz ~{plot_output_dir}/
                echo "Plots archived successfully"
            fi
        else
            echo "plot-vcfstats not available, skipping plot generation"
        fi
        
        # If Azure storage parameters are provided, prepare for upload
        ~{if defined(azure_storage_account) then "echo 'Azure storage account: " + azure_storage_account + "'" else ""}
        ~{if defined(azure_container_name) then "echo 'Azure container: " + azure_container_name + "'" else ""}
    >>>

    output {
        File stats_output = stats_output_name
        File? plot_files = "${plot_output_dir}.tar.gz"
        File stats_summary = stats_summary_name
    }

    runtime {
        docker: docker_image
        memory: "${memory_gb} GB"
        disks: "local-disk ${disk_size_gb} HDD"
        cpu: cpu
        maxRetries: max_retries
        preemptible: preemptible_tries
        
        # Azure-specific runtime attributes
        # These may vary based on your Azure Batch configuration
        backend: "AzureBatch"
    }
}
