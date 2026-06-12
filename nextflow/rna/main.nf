nextflow.enable.dsl = 2

params.reads = null
params.adapters = null
params.reference_index = null
params.annotation = null
params.strandedness = 0
params.outdir = './results'

process TRIMMOMATIC {
    container 'quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7'
    publishDir "${params.outdir}/trimmomatic", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(reads)
        path adapters

    output:
        tuple val(sample), path("${sample}_R1.trimmed.fastq.gz"), path("${sample}_R2.trimmed.fastq.gz"), path("${sample}_R1.unpaired.fastq.gz"), path("${sample}_R2.unpaired.fastq.gz"), emit: trimmed_reads
        path("${sample}.trimmomatic.log"), emit: log

    """
    trimmomatic PE \
        -threads ${task.cpus} \
        ${reads[0]} ${reads[1]} \
        ${sample}_R1.trimmed.fastq.gz ${sample}_R1.unpaired.fastq.gz \
        ${sample}_R2.trimmed.fastq.gz ${sample}_R2.unpaired.fastq.gz \
        ILLUMINACLIP:${adapters}:2:30:10 \
        LEADING:3 TRAILING:3 \
        SLIDINGWINDOW:4:15 MINLEN:36 \
        2> ${sample}.trimmomatic.log
    """
}

process STAR_ALIGN {
    container 'quay.io/biocontainers/star:2.7.3a--0'
    publishDir "${params.outdir}/star", mode: 'copy'
    cpus 8
    memory '32 GB'
    disk '20 GB'

    input:
        tuple val(sample), path(reads)
        path reference_index

    output:
        tuple val(sample), path("star_${sample}/Aligned.sortedByCoord.out.bam"), emit: alignment
        path("star_${sample}/Log.final.out"), emit: star_logs

    """
    mkdir -p star_${sample}
    STAR --runMode alignReads \
        --runThreadN ${task.cpus} \
        --genomeDir ${reference_index} \
        --readFilesIn ${reads[0]} ${reads[1]} \
        --readFilesCommand zcat \
        --outFileNamePrefix star_${sample}/ \
        --outSAMtype BAM SortedByCoordinate \
        --outBAMcompression 1 \
        --outSAMunmapped Within KeepPairs \
        --outSAMattrRGline ID:${sample} LB:1 PL:ILLUMINA SM:${sample} \
        --twopassMode Basic
    """
}

process FASTQC {
    container 'quay.io/biocontainers/fastqc:0.11.9--0'
    publishDir "${params.outdir}/fastqc", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '2 GB'

    input:
        tuple val(sample), path(reads)

    output:
        path("fastqc_${sample}/*_fastqc.html"), emit: reports
        path("fastqc_${sample}/*_fastqc.zip"), emit: archives

    """
    mkdir -p fastqc_${sample}
    fastqc \
        --threads ${task.cpus} \
        --outdir fastqc_${sample} \
        ${reads[0]} ${reads[1]}
    """
}

process FEATURECOUNTS {
    container 'quay.io/biocontainers/subread:2.0.1--hed695b0_0'
    publishDir "${params.outdir}/featurecounts", mode: 'copy'
    cpus 4
    memory '8 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(bam)
        path annotation
        val strandedness

    output:
        path("${sample}_counts.txt"), emit: counts
        path("${sample}_counts.txt.summary"), emit: summary

    """
    featureCounts \
        -T ${task.cpus} \
        -a ${annotation} \
        -o ${sample}_counts.txt \
        -s ${strandedness} \
        ${bam}
    """
}

workflow {
    reads_ch = Channel.fromFilePairs(params.reads)
    adapters = file(params.adapters)
    reference_index = file(params.reference_index)
    annotation = file(params.annotation)

    TRIMMOMATIC(reads_ch, adapters)
    STAR_ALIGN(TRIMMOMATIC.out.trimmed_reads, reference_index)
    FASTQC(TRIMMOMATIC.out.trimmed_reads)
    FEATURECOUNTS(
        STAR_ALIGN.out.alignment.map { sample, bam -> tuple(sample, bam) },
        annotation,
        params.strandedness
    )
}
