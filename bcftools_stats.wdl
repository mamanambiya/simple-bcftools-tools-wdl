version 1.0

workflow BcftoolsStats {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix = "bcftools_stats"
        String? regions
        String? targets
        Int? threads = 1
    }

    call RunBcftoolsStats {
        input:
            vcf_file = vcf_file,
            vcf_index = vcf_index,
            output_prefix = output_prefix,
            regions = regions,
            targets = targets,
            threads = threads
    }

    output {
        File stats_output = RunBcftoolsStats.stats_output
        File? plot_files = RunBcftoolsStats.plot_files
    }

    meta {
        description: "A simple workflow to generate statistics from VCF/BCF files using bcftools stats"
        author: "WDL Workflow"
    }
}

task RunBcftoolsStats {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix
        String? regions
        String? targets
        Int threads
        
        # Runtime parameters
        String docker = "biocontainers/bcftools:v1.19-1-deb_cv1"
        Int memory_gb = 4
        Int disk_size_gb = 50
        Int cpu = threads
    }

    String stats_output_name = "${output_prefix}.stats.txt"
    String plot_output_dir = "${output_prefix}_plots"

    command <<<
        set -euo pipefail
        
        # Create output directory for plots
        mkdir -p ~{plot_output_dir}
        
        # Run bcftools stats
        bcftools stats \
            ~{"--regions " + regions} \
            ~{"--targets " + targets} \
            --threads ~{threads} \
            ~{vcf_file} \
            > ~{stats_output_name}
        
        # Generate plots if plot-vcfstats is available
        if command -v plot-vcfstats &> /dev/null; then
            plot-vcfstats -p ~{plot_output_dir}/ ~{stats_output_name} || true
            
            # Create a tar of plot files if they were generated
            if [ -d "~{plot_output_dir}" ] && [ "$(ls -A ~{plot_output_dir})" ]; then
                tar -czf ~{plot_output_dir}.tar.gz ~{plot_output_dir}/
            fi
        fi
    >>>

    output {
        File stats_output = stats_output_name
        File? plot_files = "${plot_output_dir}.tar.gz"
    }

    runtime {
        docker: docker
        memory: "${memory_gb} GB"
        disks: "local-disk ${disk_size_gb} HDD"
        cpu: cpu
        preemptible: 3
    }
}
