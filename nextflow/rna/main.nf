nextflow.enable.dsl = 2

params.reads = null
params.adapters = null
params.reference_index = null
params.annotation = null

process TRIMMOMATIC {
    #? disk = 1024
    cpus 2
    memory '4 GB'

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
    #? disk = 10240
    cpus 8
    memory '32 GB'

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
    #? disk = 512
    cpus 2
    memory '4 GB'

    input:
        path reads
    
    output:
        path "*.html", emit: reports
    
    """
    fastqc --outdir . ${reads.join(' ')}
    """
}

process FEATURECOUNTS {
    #? disk = 1024
    cpus 4
    memory '8 GB'

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
    STAR_ALIGN(TRIMMOMATIC.out.trimmed_reads.collect(), reference_index)
    FASTQC(TRIMMOMATIC.out.trimmed_reads.collect())
    FEATURECOUNTS(STAR_ALIGN.out.alignment.first(), annotation)

    emit:
        counts = FEATURECOUNTS.out.counts
        reports = FASTQC.out.reports
}