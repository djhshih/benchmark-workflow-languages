version 1.0

workflow quality_control {
    Array[File] reads
    File reference_index
    File adapters

    call fastqc {
        input:
            reads = reads
    }

    call trimmomatic {
        input:
            reads = reads,
            adapters = adapters
    }

    call fastqc as post_qc {
        input:
            reads = trimmomatic.trimmed_reads
    }

    call bowtie2 {
        input:
            reads = trimmomatic.trimmed_reads,
            reference_index = reference_index
    }

    output {
        Array[File] trimmed_reports = trimmomatic.step_log
        File alignment = bowtie2.sorted_bam
        Array[File] qc_reports = fastqc.reports
    }
}

task fastqc {
    Array[File] reads

    command <<<
        fastqc ~{sep=' ' reads}
    >>>

    runtime {
        cpu: 1
        memory: "2 GB"
    }

    output {
        Array[File] reports = glob("*.html")
    }
}

task trimmomatic {
    Array[File] reads
    File adapters

    command <<<
        java -jar trimmomatic.jar PE ~{reads[0]} ~{reads[1]} \
            trimmed_R1.fastq.gz trimmed_R2.fastq.gz \
            ILLUMINACLIP:adapters.fa:2:30:10 \
            LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        Array[File] trimmed_reads = glob("*.fastq.gz")
        File step_log = glob("*_log.txt")[0]
    }
}

task bowtie2 {
    Array[File] reads
    File reference_index

    command <<<
        bowtie2 -x ~{reference_index} -1 ~{reads[0]} -2 ~{reads[1]} \
            --threads ~{cpu} -S alignment.sam
    >>>

    runtime {
        cpu: 4
        memory: "8 GB"
    }

    output {
        File sorted_bam = glob("*.bam")[0]
    }
}