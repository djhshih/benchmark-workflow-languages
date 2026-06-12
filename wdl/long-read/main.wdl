version 1.0

workflow long_read_variant_calling {
    input {
        String sample_name
        File reads
        File reference_fasta
        File reference_fasta_fai
        String platform = "ont"
        String minipreset = "map-ont"
        String clair3_model = "r941_prom_sup_g5014"
        Boolean run_modkit = false
    }

    call minimap2_map {
        input:
            sample_name = sample_name,
            reads = reads,
            reference_fasta = reference_fasta,
            preset = minipreset,
            platform = platform
    }

    call mosdepth_cov {
        input:
            sample_name = sample_name,
            bam = minimap2_map.output_bam,
            bam_index = minimap2_map.output_bam_index
    }

    call clair3_call {
        input:
            sample_name = sample_name,
            bam = minimap2_map.output_bam,
            bam_index = minimap2_map.output_bam_index,
            reference_fasta = reference_fasta,
            reference_fasta_fai = reference_fasta_fai,
            platform = platform,
            model = clair3_model
    }

    call bcftools_stats {
        input:
            sample_name = sample_name,
            input_vcf = clair3_call.output_vcf,
            input_vcf_index = clair3_call.output_vcf_index
    }

    call multiqc_report {
        input:
            sample_name = sample_name,
            reports = [mosdepth_cov.summary, bcftools_stats.stats]
    }

    output {
        File alignment = minimap2_map.output_bam
        File alignment_index = minimap2_map.output_bam_index
        File variants = clair3_call.output_vcf
        File variants_index = clair3_call.output_vcf_index
        File vcf_stats = bcftools_stats.stats
        File coverage_summary = mosdepth_cov.summary
        File multiqc_report = multiqc_report.report
    }
}

task minimap2_map {
    input {
        String sample_name
        File reads
        File reference_fasta
        String preset = "map-ont"
        String platform = "ont"
        Int threads = 8
        Int sort_threads = 2
        Int memory_gb = 24
        Int time_minutes = 60
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0"
    }

    command {
        minimap2 \
            -a \
            -x ~{preset} \
            -t ~{threads} \
            -y \
            -R "@RG\tID:~{sample_name}\tSM:~{sample_name}\tPL:~{platform}" \
            ~{reference_fasta} \
            ~{reads} | \
        samtools sort \
            --threads ~{sort_threads} \
            -m 1G \
            -o ~{sample_name}.sorted.bam \
            - && \
        samtools index ~{sample_name}.sorted.bam
    }

    output {
        File output_bam = "~{sample_name}.sorted.bam"
        File output_bam_index = "~{sample_name}.sorted.bam.bai"
    }

    runtime {
        cpu: threads
        memory: "~{memory_gb} GB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        reads: {description: "Long-read FASTQ or uBAM file.", category: "required"}
        reference_fasta: {description: "Reference FASTA file.", category: "required"}
        preset: {description: "Minimap2 preset (map-ont, map-pb, etc.).", category: "common"}
        threads: {description: "Number of threads for alignment.", category: "advanced"}
        docker_image: {description: "Docker image.", category: "advanced"}
        output_bam: {description: "Sorted BAM alignment."}
        output_bam_index: {description: "Index of sorted BAM."}
    }
}

task mosdepth_cov {
    input {
        String sample_name
        File bam
        File bam_index
        Int threads = 4
        Int memory_mb = 4096
        Int time_minutes = 30
        Int disk_gb = 2
        String docker_image = "quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1"
    }

    command {
        mosdepth \
            --threads ~{threads} \
            --no-per-base \
            ~{sample_name}.mosdepth \
            ~{bam}
    }

    output {
        File summary = "~{sample_name}.mosdepth.mosdepth.summary.txt"
        File global_dist = "~{sample_name}.mosdepth.mosdepth.global.dist.txt"
    }

    runtime {
        cpu: threads
        memory: "~{memory_mb} MB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        bam: {description: "Sorted BAM file.", category: "required"}
        bam_index: {description: "BAM index.", category: "required"}
        threads: {description: "Number of threads.", category: "advanced"}
        summary: {description: "Coverage summary."}
        global_dist: {description: "Global coverage distribution."}
    }
}

task clair3_call {
    input {
        String sample_name
        File bam
        File bam_index
        File reference_fasta
        File reference_fasta_fai
        String platform = "ont"
        String model = "r941_prom_sup_g5014"
        Int threads = 8
        String memory = "~{threads + 16}GiB"
        Int time_minutes = 120
        Int disk_gb = 20
        String docker_image = "quay.io/biocontainers/clair3:1.1.0--py39hd649744_0"
    }

    command {
        run_clair3.sh \
            --model=~{model} \
            --ref_fn=~{reference_fasta} \
            --bam_fn=~{bam} \
            --output=clair3_out \
            --threads=~{threads} \
            --platform=~{platform} \
            --sample_name=~{sample_name}
        mv clair3_out/merge_output.vcf.gz ~{sample_name}.clair3.vcf.gz
        mv clair3_out/merge_output.vcf.gz.tbi ~{sample_name}.clair3.vcf.gz.tbi
        rm -rf clair3_out
    }

    output {
        File output_vcf = "~{sample_name}.clair3.vcf.gz"
        File output_vcf_index = "~{sample_name}.clair3.vcf.gz.tbi"
    }

    runtime {
        cpu: threads
        memory: memory
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        bam: {description: "Sorted BAM file.", category: "required"}
        bam_index: {description: "BAM index.", category: "required"}
        reference_fasta: {description: "Reference FASTA.", category: "required"}
        reference_fasta_fai: {description: "Reference FASTA index.", category: "required"}
        platform: {description: "Sequencing platform: ont or hifi.", category: "common"}
        model: {description: "Clair3 model name.", category: "common"}
        threads: {description: "Number of threads.", category: "advanced"}
        output_vcf: {description: "Clair3 VCF output."}
        output_vcf_index: {description: "Clair3 VCF index."}
    }
}

task bcftools_stats {
    input {
        String sample_name
        File input_vcf
        File input_vcf_index
        Int memory_mb = 256
        Int time_minutes = 10
        Int disk_gb = 1
        String docker_image = "quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2"
    }

    command {
        bcftools stats \
            ~{input_vcf} > ~{sample_name}.vcf.stats
    }

    output {
        File stats = "~{sample_name}.vcf.stats"
    }

    runtime {
        memory: "~{memory_mb} MB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        input_vcf: {description: "Input VCF file.", category: "required"}
        input_vcf_index: {description: "Input VCF index.", category: "required"}
        stats: {description: "bcftools stats output."}
    }
}

task multiqc_report {
    input {
        String sample_name
        Array[File] reports
        Int time_minutes = 5
        Int disk_gb = 1
        String docker_image = "quay.io/biocontainers/multiqc:1.28--pyhdfd78af_0"
    }

    command {
        multiqc \
            --force \
            --outdir ~{sample_name}_multiqc \
            ~{sep=' ' reports}
    }

    output {
        File report = "~{sample_name}_multiqc/multiqc_report.html"
    }

    runtime {
        memory: "2 GB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        reports: {description: "Reports to aggregate.", category: "required"}
        report: {description: "MultiQC HTML report."}
    }
}
