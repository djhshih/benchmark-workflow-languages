version 1.0

workflow snv_calling {
    input {
        String sample_name
        Array[File] reads
        File reference
        File reference_dict
        File reference_fai
        Array[File] known_sites
        Array[File] known_sites_indices
        File dbsnp_vcf
        File dbsnp_vcf_index
        File dbsnp_vcf_for_recal
        File dbsnp_vcf_for_recal_index
    }

    call bwa_mem {
        input:
            sample_name = sample_name,
            reads = reads,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai
    }

    call mark_duplicates {
        input:
            input_bam = bwa_mem.output_bam,
            input_bam_index = bwa_mem.output_bam_index,
            sample_name = sample_name
    }

    call base_recalibrator {
        input:
            input_bam = mark_duplicates.deduped_bam,
            input_bam_index = mark_duplicates.deduped_bam_index,
            sample_name = sample_name,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai,
            known_sites = known_sites,
            known_sites_indices = known_sites_indices,
            dbsnp_vcf = dbsnp_vcf,
            dbsnp_vcf_index = dbsnp_vcf_index
    }

    call apply_bqsr {
        input:
            input_bam = mark_duplicates.deduped_bam,
            input_bam_index = mark_duplicates.deduped_bam_index,
            sample_name = sample_name,
            recal_table = base_recalibrator.recal_table,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai
    }

    call haplotype_caller {
        input:
            input_bam = apply_bqsr.recalibrated_bam,
            input_bam_index = apply_bqsr.recalibrated_bam_index,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai,
            sample_name = sample_name
    }

    call variant_recalibrator {
        input:
            input_vcf = haplotype_caller.output_vcf,
            input_vcf_index = haplotype_caller.output_vcf_index,
            sample_name = sample_name,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai,
            dbsnp_vcf = dbsnp_vcf_for_recal,
            dbsnp_vcf_index = dbsnp_vcf_for_recal_index
    }

    output {
        File variants = variant_recalibrator.filtered_vcf
        File variants_index = variant_recalibrator.filtered_vcf_index
        File recal_table = base_recalibrator.recal_table
        File alignment = mark_duplicates.deduped_bam
        File alignment_index = mark_duplicates.deduped_bam_index
        File recalibrated_bam = apply_bqsr.recalibrated_bam
        File recalibrated_bam_index = apply_bqsr.recalibrated_bam_index
        File dedup_metrics = mark_duplicates.metrics
    }
}

task bwa_mem {
    input {
        String sample_name
        Array[File] reads
        File reference
        File reference_dict
        File reference_fai
        String library = "1"
        String platform = "ILLUMINA"
        Int threads = 4
        Int memory_gb = 8
        Int time_minutes = 60
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0"
    }

    command {
        bwa mem \
            -t ~{threads} \
            -R "@RG\tID:~{sample_name}\tLB:1\tPL:ILLUMINA\tSM:~{sample_name}" \
            ~{reference} \
            ~{reads[0]} \
            ~{reads[1]} \
            2> ~{sample_name}.bwa.log | \
        samtools sort \
            -@ ~{threads - 1} \
            -m 2G \
            -o ~{sample_name}.sorted.bam \
            - && \
        samtools index ~{sample_name}.sorted.bam
    }

    output {
        File output_bam = "~{sample_name}.sorted.bam"
        File output_bam_index = "~{sample_name}.sorted.bam.bai"
        File bwa_log = "~{sample_name}.bwa.log"
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
        reads: {description: "Paired-end FASTQ files.", category: "required"}
        reference: {description: "Reference FASTA file.", category: "required"}
        reference_dict: {description: "Sequence dictionary for reference.", category: "required"}
        reference_fai: {description: "FASTA index for reference.", category: "required"}
        threads: {description: "Number of threads for BWA and sorting.", category: "advanced"}
        memory_gb: {description: "Memory in GB.", category: "advanced"}
        docker_image: {description: "Docker image containing BWA and samtools.", category: "advanced"}
        output_bam: {description: "Sorted BAM file."}
        output_bam_index: {description: "Index of sorted BAM."}
        bwa_log: {description: "BWA alignment log."}
    }
}

task mark_duplicates {
    input {
        File input_bam
        File input_bam_index
        String sample_name
        Int memory_mb = 7168
        Int time_minutes = 120
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/picard:3.3.0--hdfd78af_0"
    }

    command {
        picard MarkDuplicates \
            INPUT=~{input_bam} \
            OUTPUT=~{sample_name}.deduped.bam \
            METRICS_FILE=~{sample_name}.deduped.metrics.txt \
            CREATE_INDEX=true \
            VALIDATION_STRINGENCY=SILENT \
            OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
            CLEAR_DT=false
    }

    output {
        File deduped_bam = "~{sample_name}.deduped.bam"
        File deduped_bam_index = "~{sample_name}.deduped.bai"
        File metrics = "~{sample_name}.deduped.metrics.txt"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "Sorted input BAM.", category: "required"}
        input_bam_index: {description: "Input BAM index.", category: "required"}
        sample_name: {description: "Sample identifier.", category: "required"}
        deduped_bam: {description: "BAM with duplicates marked."}
        deduped_bam_index: {description: "Index of deduplicated BAM."}
        metrics: {description: "MarkDuplicates metrics."}
    }
}

task base_recalibrator {
    input {
        File input_bam
        File input_bam_index
        String sample_name
        File reference
        File reference_dict
        File reference_fai
        Array[File] known_sites
        Array[File] known_sites_indices
        File dbsnp_vcf
        File dbsnp_vcf_index
        Int memory_mb = 1536
        Int time_minutes = 120
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx1024M -XX:ParallelGCThreads=1" \
            BaseRecalibrator \
            --use-original-qualities \
            -I ~{input_bam} \
            -R ~{reference} \
            --known-sites ~{dbsnp_vcf} \
            -O ~{sample_name}.recal.table
    }

    output {
        File recal_table = "~{sample_name}.recal.table"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "Deduplicated input BAM.", category: "required"}
        input_bam_index: {description: "Input BAM index.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        reference_dict: {description: "Sequence dictionary.", category: "required"}
        reference_fai: {description: "FASTA index.", category: "required"}
        known_sites: {description: "Known sites VCFs for recalibration.", category: "required"}
        dbsnp_vcf: {description: "dbSNP VCF.", category: "required"}
        recal_table: {description: "BQSR recalibration table."}
    }
}

task apply_bqsr {
    input {
        File input_bam
        File input_bam_index
        String sample_name
        File recal_table
        File reference
        File reference_dict
        File reference_fai
        Int memory_mb = 2560
        Int time_minutes = 120
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx2048M -XX:ParallelGCThreads=1" \
            ApplyBQSR \
            --create-output-bam-md5 \
            --add-output-sam-program-record \
            -R ~{reference} \
            -I ~{input_bam} \
            --use-original-qualities \
            -O ~{sample_name}.recalibrated.bam \
            -bqsr ~{recal_table} \
            --static-quantized-quals 10 \
            --static-quantized-quals 20 \
            --static-quantized-quals 30
    }

    output {
        File recalibrated_bam = "~{sample_name}.recalibrated.bam"
        File recalibrated_bam_index = "~{sample_name}.recalibrated.bai"
        File recalibrated_bam_md5 = "~{sample_name}.recalibrated.bam.md5"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "Deduplicated input BAM.", category: "required"}
        input_bam_index: {description: "Input BAM index.", category: "required"}
        recal_table: {description: "BQSR recalibration table.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        recalibrated_bam: {description: "Recalibrated BAM."}
        recalibrated_bam_index: {description: "Index of recalibrated BAM."}
        recalibrated_bam_md5: {description: "MD5 of recalibrated BAM."}
    }
}

task haplotype_caller {
    input {
        File input_bam
        File input_bam_index
        File reference
        File reference_dict
        File reference_fai
        String sample_name
        Int memory_mb = 4608
        Int time_minutes = 400
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx4096M -XX:ParallelGCThreads=1" \
            HaplotypeCaller \
            -R ~{reference} \
            -I ~{input_bam} \
            -O ~{sample_name}.g.vcf.gz \
            --emit-ref-confidence GVCF
    }

    output {
        File output_vcf = "~{sample_name}.g.vcf.gz"
        File output_vcf_index = "~{sample_name}.g.vcf.gz.tbi"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "Recalibrated BAM.", category: "required"}
        input_bam_index: {description: "Recalibrated BAM index.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        sample_name: {description: "Sample identifier.", category: "required"}
        output_vcf: {description: "GVCF file with raw variant calls."}
        output_vcf_index: {description: "Index of GVCF file."}
    }
}

task variant_recalibrator {
    input {
        File input_vcf
        File input_vcf_index
        String sample_name
        File reference
        File reference_dict
        File reference_fai
        File dbsnp_vcf
        File dbsnp_vcf_index
        Int memory_mb = 8704
        Int time_minutes = 180
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx8192M -XX:ParallelGCThreads=1" \
            VariantRecalibrator \
            -R ~{reference} \
            -V ~{input_vcf} \
            --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 ~{dbsnp_vcf} \
            -O ~{sample_name}.variant_filter.vcf.gz \
            --tranches-file ~{sample_name}.tranches \
            --rscript-file ~{sample_name}.plots.R \
            --tranche 100.0 \
            --tranche 99.9 \
            --tranche 99.0 \
            --tranche 90.0 \
            --max-gaussians 4
    }

    output {
        File filtered_vcf = "~{sample_name}.variant_filter.vcf.gz"
        File filtered_vcf_index = "~{sample_name}.variant_filter.vcf.gz.tbi"
        File tranches = "~{sample_name}.tranches"
        File r_script = "~{sample_name}.plots.R"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_vcf: {description: "GVCF file from HaplotypeCaller.", category: "required"}
        input_vcf_index: {description: "GVCF index.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        dbsnp_vcf: {description: "dbSNP VCF for VQSR training.", category: "required"}
        filtered_vcf: {description: "VQSR-filtered VCF."}
        filtered_vcf_index: {description: "Index of filtered VCF."}
    }
}
