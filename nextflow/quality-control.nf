#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

params.reads = null
params.reference = null
params.adapters = null

process FASTQC {
    cpus 1
    memory '2 GB'
    
    input:
        path reads
    
    output:
        path "*.html", emit: reports
    
    """
    fastqc ${reads.join(' ')}
    """
}

process TRIMMOMATIC {
    cpus 2
    memory '4 GB'
    
    input:
        path reads
        path adapters
    
    output:
        path "trimmed_*.fastq.gz", emit: trimmed_reads
        path "*_log.txt", emit: step_log
    
    """
    java -jar trimmomatic.jar PE ${reads[0]} ${reads[1]} \
        trimmed_R1.fastq.gz trimmed_R2.fastq.gz \
        ILLUMINACLIP:adapters.fa:2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    """
}

process BOWTIE2 {
    cpus 4
    memory '8 GB'
    
    input:
        path reads
        path reference_index
    
    output:
        path "*.bam", emit: sorted_bam
    
    """
    bowtie2 -x ${reference_index} -1 ${reads[0]} -2 ${reads[1]} \
        --threads $task.cpus -S alignment.sam
    """
}

workflow {
    reads = Channel.fromFilePairs(params.reads)
    adapters = file(params.adapters)
    reference_index = file(params.reference)
    
    // Initial QC
    FASTQC(reads)
    
    // Trimming
    TRIMMOMATIC(reads, adapters)
    
    // Post-trim QC
    FASTQC(TRIMMOMATIC.out.trimmed_reads)
    
    // Alignment
    BOWTIE2(TRIMMOMATIC.out.trimmed_reads, reference_index)
    
    // Output
    emit:
        trimmed_reports = TRIMMOMATIC.out.step_log
        alignment = BOWTIE2.out.sorted_bam
        qc_reports = FASTQC.out.reports
}