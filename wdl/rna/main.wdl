version 1.0

task trimmomatic {
    input {
        Array[File] reads
        File adapters
        Int cpu = 2
        Int memory_gb = 4
    }
    
    command <<<
        java -jar trimmomatic.jar PE ~{reads[0]} ~{reads[1]} \
            trimmed_R1.fastq.gz trimmed_R1_unpaired.fastq.gz \
            trimmed_R2.fastq.gz trimmed_R2_unpaired.fastq.gz \
            ILLUMINACLIP:~{adapters}:2:30:10 LEADING:3 TRAILING:3 \
            SLIDINGWINDOW:4:15 MINLEN:36
    >>>
    
    output {
        Array[File] trimmed_reads = glob("trimmed_*.fastq.gz")
        Array[File] logs = glob("*_log.txt")
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

task star_align {
    input {
        Array[File] reads
        File reference_index
        Int cpu = 8
        Int memory_gb = 32
    }
    
    command <<<
        mkdir -p star_out
        STAR --runMode alignReads --runThreadN ~{cpu} \
            --genomeDir ~{reference_index} --readFilesIn ~{reads[0]} ~{reads[1]} \
            --outFileNamePrefix star_out/
    >>>
    
    output {
        File alignment = glob("star_out/*.bam")[0]
        File log = glob("star_out/*.log")[0]
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

task fastqc {
    input {
        Array[File] reads
        Int cpu = 2
        Int memory_gb = 4
    }
    
    command <<<
        fastqc --outdir . ~{sep=' ' reads}
    >>>
    
    output {
        Array[File] reports = glob("*.html")
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

task featurecounts {
    input {
        File alignment
        File annotation
        Int cpu = 4
        Int memory_gb = 8
    }
    
    command <<<
        featureCounts -T ~{cpu} -a ~{annotation} -o counts.txt ~{alignment}
    >>>
    
    output {
        File counts = "counts.txt"
        File summary = "counts.txt.summary"
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

workflow rna_seq {
    input {
        Array[File] reads
        File adapters
        File reference_index
        File annotation
    }
    
    call trimmomatic {
        input:
            reads = reads,
            adapters = adapters
    }
    
    call star_align {
        input:
            reads = trimmomatic.trimmed_reads,
            reference_index = reference_index
    }
    
    call fastqc {
        input:
            reads = trimmomatic.trimmed_reads
    }
    
    call featurecounts {
        input:
            alignment = star_align.alignment,
            annotation = annotation
    }
    
    output {
        File counts = featurecounts.counts
        Array[File] reports = fastqc.reports
    }
}