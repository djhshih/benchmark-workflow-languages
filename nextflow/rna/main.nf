nextflow.enable.dsl = 2

params.reads = null
params.adapters = null
params.reference_index = null
params.annotation = null

process TRIMMOMATIC {
    cpus 2
    memory '4 GB'
    disk '1 GB'

    input:
        tuple val(sample), path(reads)
        path adapters
    
    output:
        path "trimmed_*.fastq.gz", emit: trimmed_reads
        path "*_log.txt", emit: logs
    
    """
    java -jar trimmomatic.jar PE ${reads[0]} ${reads[1]} \
        trimmed_${sample}_R1.fastq.gz trimmed_R1_unpaired.fastq.gz \
        trimmed_${sample}_R2.fastq.gz trimmed_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${adapters}:2:30:10 LEADING:3 TRAILING:3 \
        SLIDINGWINDOW:4:15 MINLEN:36
    """
}

process STAR_ALIGN {
    cpus 8
    memory '32 GB'
    disk '10 GB'

    input:
        path reads
        path reference_index
    
    output:
        path "*.bam", emit: alignment
        path "*.log", emit: log
    
    """
    STAR --runMode alignReads --runThreadN ${task.cpus} \
        --genomeDir ${reference_index} --readFilesIn ${reads[0]} ${reads[1]} \
        --outFileNamePrefix ./
    """
}

process FASTQC {
    cpus 2
    memory '4 GB'
    disk '512 MB'

    input:
        path reads
    
    output:
        path "*.html", emit: reports
    
    """
    fastqc --outdir . ${reads[0]} ${reads[1]}
    """
}

process FEATURECOUNTS {
    cpus 4
    memory '8 GB'
    disk '1 GB'

    input:
        path alignment
        path annotation
    
    output:
        path "counts.txt", emit: counts
        path "counts.txt.summary", emit: summary
    
    """
    featureCounts -T ${task.cpus} -a ${annotation} -o counts.txt ${alignment}
    """
}

workflow {
    reads = Channel.fromFilePairs(params.reads)
    adapters = file(params.adapters)
    reference_index = file(params.reference_index)
    annotation = file(params.annotation)
    
    TRIMMOMATIC(reads, adapters)
    STAR_ALIGN(TRIMMOMATIC.out.trimmed_reads, reference_index)
    FASTQC(TRIMMOMATIC.out.trimmed_reads)
    FEATURECOUNTS(STAR_ALIGN.out.alignment, annotation)
    
    emit:
        counts = FEATURECOUNTS.out.counts
        reports = FASTQC.out.reports
}