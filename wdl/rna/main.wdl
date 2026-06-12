version 1.0

workflow rna_seq {
    input {
        String sample_name
        Array[File] reads
        File adapters
        File reference_index_dir
        File annotation_gtf
        File reference_fasta
        File reference_fasta_fai
        File reference_fasta_dict
        String strandedness = "NONE"
    }

    call trimmomatic {
        input:
            sample_name = sample_name,
            reads = reads,
            adapters = adapters
    }

    call star_align {
        input:
            sample_name = sample_name,
            reads = trimmomatic.trimmed_reads,
            reference_index_files = reference_index_dir,
            reference_fasta = reference_fasta
    }

    call fastqc {
        input:
            sample_name = sample_name,
            reads = trimmomatic.trimmed_reads
    }

    call featurecounts {
        input:
            sample_name = sample_name,
            alignment = star_align.alignment,
            alignment_index = star_align.alignment_index,
            annotation = annotation_gtf,
            strandedness = strandedness
    }

    output {
        File counts = featurecounts.counts
        File counts_summary = featurecounts.summary
        Array[File] reports = fastqc.reports
        File alignment = star_align.alignment
        File alignment_index = star_align.alignment_index
        File star_log = star_align.log
    }
}

task trimmomatic {
    input {
        String sample_name
        Array[File] reads
        File adapters
        Int threads = 2
        Int memory_mb = 4096
        Int time_minutes = 30
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7"
    }

    command {
        trimmomatic PE \
            -threads ~{threads} \
            ~{reads[0]} ~{reads[1]} \
            ~{sample_name}_R1.trimmed.fastq.gz \
            ~{sample_name}_R1.unpaired.fastq.gz \
            ~{sample_name}_R2.trimmed.fastq.gz \
            ~{sample_name}_R2.unpaired.fastq.gz \
            ILLUMINACLIP:~{adapters}:2:30:10 \
            LEADING:3 \
            TRAILING:3 \
            SLIDINGWINDOW:4:15 \
            MINLEN:36
    }

    output {
        Array[File] trimmed_reads = [
            "~{sample_name}_R1.trimmed.fastq.gz",
            "~{sample_name}_R2.trimmed.fastq.gz"
        ]
        Array[File] unpaired_reads = [
            "~{sample_name}_R1.unpaired.fastq.gz",
            "~{sample_name}_R2.unpaired.fastq.gz"
        ]
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
        reads: {description: "Paired-end FASTQ files.", category: "required"}
        adapters: {description: "Adapter FASTA file.", category: "required"}
        threads: {description: "Number of threads.", category: "advanced"}
        trimmed_reads: {description: "Trimmed paired-end FASTQ files."}
    }
}

task star_align {
    input {
        String sample_name
        Array[File] reads
        Array[File] reference_index_files
        File reference_fasta
        Int threads = 8
        Int memory_gb = 32
        Int time_minutes = 120
        Int disk_gb = 20
        String docker_image = "quay.io/biocontainers/star:2.7.3a--0"
    }

    command {
        mkdir -p "star_~{sample_name}" && \
        STAR \
            --runMode alignReads \
            --genomeDir ~{reference_index_files[0]} \
            --readFilesIn ~{reads[0]} ~{reads[1]} \
            --readFilesCommand zcat \
            --runThreadN ~{threads} \
            --outFileNamePrefix star_~{sample_name}/ \
            --outSAMtype BAM SortedByCoordinate \
            --outBAMcompression 1 \
            --outSAMunmapped Within KeepPairs \
            --twopassMode Basic \
            --outSAMattrRGline ID:~{sample_name} LB:~{sample_name} PL:ILLUMINA SM:~{sample_name}
    }

    output {
        File alignment = "star_~{sample_name}/Aligned.sortedByCoord.out.bam"
        File log = "star_~{sample_name}/Log.final.out"
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
        reads: {description: "Trimmed FASTQ files.", category: "required"}
        reference_index_files: {description: "STAR genome index files.", category: "required"}
        threads: {description: "Number of threads for STAR.", category: "advanced"}
        memory_gb: {description: "Memory in GB.", category: "advanced"}
        alignment: {description: "Sorted BAM alignment file."}
        log: {description: "STAR final log."}
    }
}

task fastqc {
    input {
        String sample_name
        Array[File] reads
        Int threads = 2
        Int memory_mb = 4096
        Int time_minutes = 15
        Int disk_gb = 2
        String docker_image = "quay.io/biocontainers/fastqc:0.11.9--0"
    }

    command {
        mkdir -p "fastqc_~{sample_name}" && \
        fastqc \
            --outdir fastqc_~{sample_name} \
            --threads ~{threads} \
            ~{sep=' ' reads}
    }

    output {
        Array[File] reports = glob("fastqc_~{sample_name}/*.html")
        Array[File] zip_reports = glob("fastqc_~{sample_name}/*.zip")
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
        reads: {description: "FASTQ files to assess.", category: "required"}
        reports: {description: "FastQC HTML reports."}
    }
}

task featurecounts {
    input {
        String sample_name
        File alignment
        File? alignment_index
        File annotation
        String strandedness = "NONE"
        Int threads = 4
        Int memory_mb = 8192
        Int time_minutes = 30
        Int disk_gb = 5
        String docker_image = "quay.io/biocontainers/subread:2.0.1--hed695b0_0"
    }

    command {
        featureCounts \
            -T ~{threads} \
            -a ~{annotation} \
            -s ~{if strandedness == "YES" then "1" else if strandedness == "REVERSE" then "2" else "0"} \
            -o ~{sample_name}_counts.txt \
            ~{alignment}
    }

    output {
        File counts = "~{sample_name}_counts.txt"
        File summary = "~{sample_name}_counts.txt.summary"
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
        alignment: {description: "Sorted BAM alignment.", category: "required"}
        annotation: {description: "GTF annotation file.", category: "required"}
        strandedness: {description: "Strandedness: NONE, YES, or REVERSE.", category: "common"}
        counts: {description: "Gene-level count table."}
        summary: {description: "FeatureCounts summary statistics."}
    }
}
