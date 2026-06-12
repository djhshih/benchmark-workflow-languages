nextflow.enable.dsl = 2

params.reads = null
params.reference = null
params.preprocessed_intervals = null
params.common_variant_sites = null
params.common_variant_sites_index = null
params.pon = null
params.outdir = './results'

process BWA_MEM {
    container 'quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0'
    publishDir "${params.outdir}/bwa", mode: 'copy'
    cpus 4
    memory '8 GB'
    disk '10 GB'

    input:
        tuple val(sample), path(reads)
        path reference

    output:
        tuple val(sample), path("${sample}.coordinate_sorted.bam"), path("${sample}.coordinate_sorted.bam.bai"), emit: alignment

    """
    bwa mem -t ${task.cpus} -R "@RG\\tID:${sample}\\tLB:1\\tPL:ILLUMINA\\tSM:${sample}" ${reference} ${reads[0]} ${reads[1]} 2> ${sample}.bwa.log | samtools sort -@ ${task.cpus - 1} -m 2G -o ${sample}.coordinate_sorted.bam -
    samtools index ${sample}.coordinate_sorted.bam
    """
}

process COLLECT_ALLELIC_COUNTS {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/alleliccounts", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(bam), path(bai)
        path reference
        path intervals
        path common_sites
        path common_sites_index

    output:
        tuple val(sample), path("${sample}.allelic_counts.tsv"), emit: allelic_counts

    """
    gatk --java-options '-Xmx10G -XX:ParallelGCThreads=1' CollectAllelicCounts \
        -I ${bam} \
        -R ${reference} \
        -L ${intervals} \
        -OVC ${common_sites} \
        -O ${sample}.allelic_counts.tsv
    """
}

process COLLECT_READ_COUNTS {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/readcounts", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(bam), path(bai)
        path reference
        path intervals

    output:
        tuple val(sample), path("${sample}.read_counts.hdf5"), emit: read_counts

    """
    gatk --java-options '-Xmx7G -XX:ParallelGCThreads=1' CollectReadCounts \
        -I ${bam} \
        -R ${reference} \
        -L ${intervals} \
        --format HDF5 \
        --interval-merging-rule OVERLAPPING_ONLY \
        -O ${sample}.read_counts.hdf5
    """
}

process DENOISE_READ_COUNTS {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/denoise", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '2 GB'

    input:
        tuple val(sample), path(read_counts)
        path(pon)

    output:
        tuple val(sample), path("${sample}.denoisedCR.tsv"), path("${sample}.standardizedCR.tsv"), emit: denoised

    script:
    def pon_args = pon ? "--count-panel-of-normals ${pon}" : ''
    """
    gatk --java-options '-Xmx4G -XX:ParallelGCThreads=1' DenoiseReadCounts \
        -I ${read_counts} \
        ${pon_args} \
        --standardized-copy-ratios ${sample}.standardizedCR.tsv \
        --denoised-copy-ratios ${sample}.denoisedCR.tsv
    """
}

process MODEL_SEGMENTS {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/modelsegments", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(denoised_cr), path(standardized_mr), path(allelic_counts)

    output:
        tuple val(sample), path("${sample}.modelFinal.seg"), path("${sample}.cr.seg"), path("${sample}.af.seg"), emit: segments

    """
    gatk --java-options '-Xmx4G -XX:ParallelGCThreads=1' ModelSegments \
        --denoised-copy-ratios ${denoised_cr} \
        --allelic-counts ${allelic_counts} \
        --output-prefix ${sample}. \
        -O .
    """
}

process CALL_COPY_RATIO_SEGMENTS {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/callsegments", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '2 GB'

    input:
        tuple val(sample), path(segments)

    output:
        tuple val(sample), path("${sample}.called.seg"), emit: calls

    """
    gatk --java-options '-Xmx2G -XX:ParallelGCThreads=1' CallCopyRatioSegments \
        -I ${segments} \
        -O ${sample}.called.seg
    """
}

workflow {
    reads_ch = Channel.fromFilePairs(params.reads)
    reference = file(params.reference)
    intervals = file(params.preprocessed_intervals)
    common_sites = file(params.common_variant_sites)
    common_sites_index = file(params.common_variant_sites_index)
    pon_file = params.pon ? file(params.pon) : []

    BWA_MEM(reads_ch, reference)

    BWA_MEM.out.alignment
        .set { bam_with_index }

    COLLECT_ALLELIC_COUNTS(
        bam_with_index,
        reference,
        intervals,
        common_sites,
        common_sites_index
    )

    COLLECT_READ_COUNTS(bam_with_index, reference, intervals)

    DENOISE_READ_COUNTS(COLLECT_READ_COUNTS.out.read_counts, pon_file)

    DENOISE_READ_COUNTS.out.denoised
        .join(COLLECT_ALLELIC_COUNTS.out.allelic_counts)
        .set { model_input }

    MODEL_SEGMENTS(model_input)
    CALL_COPY_RATIO_SEGMENTS(
        MODEL_SEGMENTS.out.segments.map { sample, modelFinal, cr, af -> tuple(sample, cr) }
    )
}
