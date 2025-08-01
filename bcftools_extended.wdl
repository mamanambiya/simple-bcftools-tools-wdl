version 1.0

# Extended bcftools workflow demonstrating multiple bcftools commands

workflow BcftoolsExtended {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix = "bcftools_analysis"
        String? regions
        String? targets
        Int threads = 1
        Boolean run_stats = true
        Boolean run_query = true
        Boolean run_view = true
    }

    if (run_stats) {
        call RunBcftoolsStats {
            input:
                vcf_file = vcf_file,
                vcf_index = vcf_index,
                output_prefix = output_prefix + "_stats",
                regions = regions,
                targets = targets,
                threads = threads
        }
    }

    if (run_query) {
        call RunBcftoolsQuery {
            input:
                vcf_file = vcf_file,
                vcf_index = vcf_index,
                output_prefix = output_prefix + "_query",
                regions = regions
        }
    }

    if (run_view) {
        call RunBcftoolsView {
            input:
                vcf_file = vcf_file,
                vcf_index = vcf_index,
                output_prefix = output_prefix + "_filtered",
                regions = regions,
                threads = threads
        }
    }

    output {
        File? stats_output = RunBcftoolsStats.stats_output
        File? query_output = RunBcftoolsQuery.query_output
        File? filtered_vcf = RunBcftoolsView.filtered_vcf
        File? filtered_vcf_index = RunBcftoolsView.filtered_vcf_index
    }
}

# Task: bcftools stats
task RunBcftoolsStats {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix
        String? regions
        String? targets
        Int threads
        
        String docker = "biocontainers/bcftools:v1.19-1-deb_cv1"
        Int memory_gb = 4
        Int disk_size_gb = 50
    }

    command <<<
        set -euo pipefail
        
        bcftools stats \
            ~{"--regions " + regions} \
            ~{"--targets " + targets} \
            --threads ~{threads} \
            ~{vcf_file} \
            > ~{output_prefix}.txt
    >>>

    output {
        File stats_output = "${output_prefix}.txt"
    }

    runtime {
        docker: docker
        memory: "${memory_gb} GB"
        disks: "local-disk ${disk_size_gb} HDD"
        cpu: threads
    }
}

# Task: bcftools query - extract specific fields
task RunBcftoolsQuery {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix
        String? regions
        
        String docker = "biocontainers/bcftools:v1.19-1-deb_cv1"
        Int memory_gb = 2
        Int disk_size_gb = 50
    }

    command <<<
        set -euo pipefail
        
        # Extract sample names, chromosome, position, REF, ALT, and genotypes
        bcftools query \
            ~{"--regions " + regions} \
            --format '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%FILTER[\t%GT]\n' \
            ~{vcf_file} \
            > ~{output_prefix}.tsv
        
        # Also create a header file
        echo -e "#CHROM\tPOS\tREF\tALT\tQUAL\tFILTER\tGENOTYPES" > ~{output_prefix}_header.tsv
        cat ~{output_prefix}.tsv >> ~{output_prefix}_header.tsv
        mv ~{output_prefix}_header.tsv ~{output_prefix}.tsv
    >>>

    output {
        File query_output = "${output_prefix}.tsv"
    }

    runtime {
        docker: docker
        memory: "${memory_gb} GB"
        disks: "local-disk ${disk_size_gb} HDD"
    }
}

# Task: bcftools view - filter variants
task RunBcftoolsView {
    input {
        File vcf_file
        File? vcf_index
        String output_prefix
        String? regions
        Int threads
        
        # Filtering parameters
        Float min_qual = 30.0
        Float min_af = 0.01
        String filter_string = "PASS"
        
        String docker = "biocontainers/bcftools:v1.19-1-deb_cv1"
        Int memory_gb = 4
        Int disk_size_gb = 50
    }

    command <<<
        set -euo pipefail
        
        # Filter variants based on quality and allele frequency
        bcftools view \
            ~{"--regions " + regions} \
            --threads ~{threads} \
            --apply-filters ~{filter_string} \
            --min-af ~{min_af} \
            --exclude 'QUAL<~{min_qual}' \
            --output-type z \
            --output ~{output_prefix}.vcf.gz \
            ~{vcf_file}
        
        # Index the output file
        bcftools index --tbi ~{output_prefix}.vcf.gz
    >>>

    output {
        File filtered_vcf = "${output_prefix}.vcf.gz"
        File filtered_vcf_index = "${output_prefix}.vcf.gz.tbi"
    }

    runtime {
        docker: docker
        memory: "${memory_gb} GB"
        disks: "local-disk ${disk_size_gb} HDD"
        cpu: threads
    }
}
