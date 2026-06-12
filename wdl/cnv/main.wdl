version 1.0

workflow cnv_calling {
    input {
        String sample_name
        Array[File] reads
        File reference
        File reference_dict
        File reference_fai
        File preprocessed_intervals
        File common_variant_sites
        File common_variant_sites_index
        File? pon
        File? annotated_intervals
    }

    call bwa_mem {
        input:
            sample_name = sample_name,
            reads = reads,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai
    }

    call sort_bam {
        input:
            input_bam = bwa_mem.output_bam,
            sample_name = sample_name
    }

    call index_bam {
        input:
            bam = sort_bam.sorted_bam
    }

    call collect_allelic_counts {
        input:
            input_bam = index_bam.indexed_bam,
            input_bam_index = index_bam.index,
            sample_name = sample_name,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai,
            common_variant_sites = common_variant_sites,
            common_variant_sites_index = common_variant_sites_index
    }

    call collect_read_counts {
        input:
            input_bam = index_bam.indexed_bam,
            input_bam_index = index_bam.index,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai,
            intervals = preprocessed_intervals,
            sample_name = sample_name
    }

    call denoise_read_counts {
        input:
            read_counts = collect_read_counts.counts,
            sample_name = sample_name,
            pon = pon,
            annotated_intervals = annotated_intervals
    }

    call model_segments {
        input:
            sample_name = sample_name,
            denoised_copy_ratios = denoise_read_counts.denoised_copy_ratios,
            standardized_copy_ratios = denoise_read_counts.standardized_copy_ratios,
            allelic_counts = collect_allelic_counts.allelic_counts
    }

    call call_copy_ratio_segments {
        input:
            copy_ratio_segments = model_segments.copy_ratio_segments,
            sample_name = sample_name
    }

    output {
        File cnv_calls = call_copy_ratio_segments.called_segments
        File cnv_calls_igv = call_copy_ratio_segments.called_segments_igv
        File denoised_copy_ratios = denoise_read_counts.denoised_copy_ratios
        File modeled_segments = model_segments.modeled_segments
        File allelic_counts = collect_allelic_counts.allelic_counts
        File read_counts = collect_read_counts.counts
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
        threads: {description: "Number of threads for BWA and sorting.", category: "advanced"}
        memory_gb: {description: "Memory in GB.", category: "advanced"}
        docker_image: {description: "Docker image containing BWA and samtools.", category: "advanced"}
        output_bam: {description: "Sorted BAM file."}
        output_bam_index: {description: "Index of sorted BAM."}
        bwa_log: {description: "BWA alignment log."}
    }
}

task sort_bam {
    input {
        File input_bam
        String sample_name
        Int threads = 2
        Int memory_per_thread_gb = 4
        Int time_minutes = 30
        Int disk_gb = 10
        String docker_image = "quay.io/biocontainers/samtools:1.21--h96c455f_1"
    }

    command {
        samtools sort \
            -@ ~{threads} \
            -m 4G \
            -o ~{sample_name}.coordinate_sorted.bam \
            -T ~{sample_name}.tmp \
            ~{input_bam} && \
        samtools index ~{sample_name}.coordinate_sorted.bam
    }

    output {
        File sorted_bam = "~{sample_name}.coordinate_sorted.bam"
        File sorted_bam_index = "~{sample_name}.coordinate_sorted.bam.bai"
    }

    runtime {
        cpu: threads
        memory: "~{1 + threads * memory_per_thread_gb} GB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "Input BAM file.", category: "required"}
        sample_name: {description: "Sample identifier.", category: "required"}
        sorted_bam: {description: "Coordinate-sorted BAM."}
        sorted_bam_index: {description: "Index of sorted BAM."}
    }
}

task index_bam {
    input {
        File bam
        Int threads = 1
        Int time_minutes = 10
        Int disk_gb = 2
        String docker_image = "quay.io/biocontainers/samtools:1.21--h96c455f_1"
    }

    command {
        samtools index ~{bam}
    }

    output {
        File indexed_bam = bam
        File index = "~{bam}.bai"
    }

    runtime {
        cpu: threads
        memory: "2 GB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        bam: {description: "BAM file to index.", category: "required"}
        indexed_bam: {description: "Indexed BAM file."}
        index: {description: "BAM index."}
    }
}

task collect_allelic_counts {
    input {
        File input_bam
        File input_bam_index
        String sample_name
        File reference
        File reference_dict
        File reference_fai
        File common_variant_sites
        File common_variant_sites_index
        Int memory_mb = 11264
        Int time_minutes = 120
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx10G -XX:ParallelGCThreads=1" \
        CollectAllelicCounts \
        -L ~{common_variant_sites} \
        -I ~{input_bam} \
        -R ~{reference} \
        -O ~{sample_name}.allelic_counts.tsv
    }

    output {
        File allelic_counts = "~{sample_name}.allelic_counts.tsv"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "BAM file.", category: "required"}
        input_bam_index: {description: "BAM index.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        common_variant_sites: {description: "Common variant sites VCF.", category: "required"}
        allelic_counts: {description: "Allelic counts at common variant sites."}
    }
}

task collect_read_counts {
    input {
        File input_bam
        File input_bam_index
        File reference
        File reference_dict
        File reference_fai
        File intervals
        String sample_name
        Int memory_mb = 7680
        Int time_minutes = 60
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx7G -XX:ParallelGCThreads=1" \
        CollectReadCounts \
        -L ~{intervals} \
        -I ~{input_bam} \
        -R ~{reference} \
        --format HDF5 \
        --interval-merging-rule OVERLAPPING_ONLY \
        -O ~{sample_name}.read_counts.hdf5
    }

    output {
        File counts = "~{sample_name}.read_counts.hdf5"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        input_bam: {description: "BAM file.", category: "required"}
        input_bam_index: {description: "BAM index.", category: "required"}
        reference: {description: "Reference FASTA.", category: "required"}
        intervals: {description: "Preprocessed intervals.", category: "required"}
        counts: {description: "Read counts in HDF5 format."}
    }
}

task denoise_read_counts {
    input {
        File read_counts
        String sample_name
        File? pon
        File? annotated_intervals
        Int memory_mb = 5120
        Int time_minutes = 10
        Int disk_gb = 2
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" \
        DenoiseReadCounts \
        -I ~{read_counts} \
        ~{"--count-panel-of-normals " + pon} \
        --standardized-copy-ratios ~{sample_name}.standardizedCR.tsv \
        --denoised-copy-ratios ~{sample_name}.denoisedCR.tsv
    }

    output {
        File standardized_copy_ratios = "~{sample_name}.standardizedCR.tsv"
        File denoised_copy_ratios = "~{sample_name}.denoisedCR.tsv"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        read_counts: {description: "Read counts HDF5 file.", category: "required"}
        sample_name: {description: "Sample identifier.", category: "required"}
        pon: {description: "Panel of normals.", category: "common"}
        standardized_copy_ratios: {description: "Standardized copy ratios."}
        denoised_copy_ratios: {description: "GC-denoised copy ratios."}
    }
}

task model_segments {
    input {
        String sample_name
        File denoised_copy_ratios
        File standardized_copy_ratios
        File allelic_counts
        Int memory_mb = 5120
        Int time_minutes = 30
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" \
        ModelSegments \
        --denoised-copy-ratios ~{denoised_copy_ratios} \
        --allelic-counts ~{allelic_counts} \
        --output-prefix ~{sample_name}. \
        -O .
    }

    output {
        File modeled_segments = "~{sample_name}.modelFinal.seg"
        File copy_ratio_segments = "~{sample_name}.cr.seg"
        File allelic_fraction_segments = "~{sample_name}.af.seg"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        sample_name: {description: "Sample identifier.", category: "required"}
        denoised_copy_ratios: {description: "Denoised copy ratios.", category: "required"}
        allelic_counts: {description: "Allelic counts.", category: "required"}
        modeled_segments: {description: "Final modeled segments."}
        copy_ratio_segments: {description: "Copy ratio segments."}
    }
}

task call_copy_ratio_segments {
    input {
        File copy_ratio_segments
        String sample_name
        Int memory_mb = 3072
        Int time_minutes = 5
        Int disk_gb = 2
        String docker_image = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    }

    command {
        gatk --java-options "-Xmx2G -XX:ParallelGCThreads=1" \
        CallCopyRatioSegments \
        -I ~{copy_ratio_segments} \
        -O ~{sample_name}.called.seg
    }

    output {
        File called_segments = "~{sample_name}.called.seg"
        File called_segments_igv = "~{sample_name}.called.igv.seg"
    }

    runtime {
        memory: "~{memory_mb} MiB"
        time_minutes: time_minutes
        disk: "~{disk_gb} GB"
        docker: docker_image
    }

    parameter_meta {
        copy_ratio_segments: {description: "Copy ratio segments from ModelSegments.", category: "required"}
        sample_name: {description: "Sample identifier.", category: "required"}
        called_segments: {description: "Called copy ratio segments."}
    }
}
