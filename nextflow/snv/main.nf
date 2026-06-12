nextflow.enable.dsl = 2

params.reads = null
params.reference = null
params.reference_fai = null
params.reference_dict = null
params.known_sites = []
params.known_sites_indices = []
params.dbsnp_vcf = null
params.dbsnp_vcf_index = null
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
        tuple val(sample), path("${sample}.sorted.bam"), path("${sample}.sorted.bam.bai"), emit: alignment

    """
    bwa mem -t ${task.cpus} -R "@RG\\tID:${sample}\\tLB:1\\tPL:ILLUMINA\\tSM:${sample}" ${reference} ${reads[0]} ${reads[1]} 2> ${sample}.bwa.log | samtools sort -@ ${task.cpus - 1} -m 2G -o ${sample}.sorted.bam - && samtools index ${sample}.sorted.bam
    """
}

process MARK_DUPLICATES {
    container 'quay.io/biocontainers/picard:3.3.0--hdfd78af_0'
    publishDir "${params.outdir}/markduplicates", mode: 'copy'
    cpus 2
    memory '7168 MB'
    disk '10 GB'

    input:
        tuple val(sample), path(bam), path(bai)

    output:
        tuple val(sample), path("${sample}.deduped.bam"), path("${sample}.deduped.bai"), path("${sample}.deduped.metrics.txt"), emit: deduped

    """
    picard MarkDuplicates \
        INPUT=${bam} \
        OUTPUT=${sample}.deduped.bam \
        METRICS_FILE=${sample}.deduped.metrics.txt \
        CREATE_INDEX=true \
        VALIDATION_STRINGENCY=SILENT \
        OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
        CLEAR_DT=false
    """
}

process BASE_RECALIBRATOR {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/baserecalibrator", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(bam), path(bai)
        path reference
        path dbsnp_vcf
        path dbsnp_vcf_index

    output:
        tuple val(sample), path("${sample}.recal.table"), emit: recal_table

    """
    gatk --java-options '-Xmx1024M -XX:ParallelGCThreads=1' BaseRecalibrator \
        --use-original-qualities \
        -I ${bam} \
        -R ${reference} \
        --known-sites ${dbsnp_vcf} \
        -O ${sample}.recal.table
    """
}

process APPLY_BQSR {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/applybqsr", mode: 'copy'
    cpus 2
    memory '4 GB'
    disk '10 GB'

    input:
        tuple val(sample), path(bam), path(bai), path(recal_table)
        path reference

    output:
        tuple val(sample), path("${sample}.recalibrated.bam"), path("${sample}.recalibrated.bai"), path("${sample}.recalibrated.bam.md5"), emit: recalibrated

    """
    gatk --java-options '-Xmx2048M -XX:ParallelGCThreads=1' ApplyBQSR \
        --create-output-bam-md5 \
        --add-output-sam-program-record \
        -R ${reference} \
        -I ${bam} \
        --use-original-qualities \
        -O ${sample}.recalibrated.bam \
        -bqsr ${recal_table} \
        --static-quantized-quals 10 \
        --static-quantized-quals 20 \
        --static-quantized-quals 30
    """
}

process HAPLOTYPE_CALLER {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/haplotypecaller", mode: 'copy'
    cpus 4
    memory '8 GB'
    disk '10 GB'

    input:
        tuple val(sample), path(bam), path(bai)
        path reference
        path reference_fai
        path reference_dict

    output:
        tuple val(sample), path("${sample}.g.vcf.gz"), path("${sample}.g.vcf.gz.tbi"), emit: variants

    """
    gatk --java-options '-Xmx4096M -XX:ParallelGCThreads=1' HaplotypeCaller \
        -R ${reference} \
        -I ${bam} \
        -O ${sample}.g.vcf.gz \
        --emit-ref-confidence GVCF
    """
}

process VARIANT_FILTER {
    container 'quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0'
    publishDir "${params.outdir}/variantfilter", mode: 'copy'
    cpus 4
    memory '8 GB'
    disk '5 GB'

    input:
        tuple val(sample), path(vcf), path(tbi)
        path reference
        path dbsnp_vcf
        path dbsnp_vcf_index

    output:
        tuple val(sample), path("${sample}.variant_filter.vcf.gz"), path("${sample}.variant_filter.vcf.gz.tbi"), path("${sample}.tranches"), path("${sample}.plots.R"), emit: filtered_variants

    """
    gatk --java-options '-Xmx8192M -XX:ParallelGCThreads=1' VariantRecalibrator \
        -R ${reference} \
        -V ${vcf} \
        --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 ${dbsnp_vcf} \
        -O ${sample}.variant_filter.vcf.gz \
        --tranches-file ${sample}.tranches \
        --rscript-file ${sample}.plots.R \
        --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 \
        --max-gaussians 4
    """
}

workflow {
    reads_ch = Channel.fromFilePairs(params.reads)
    reference = file(params.reference)
    reference_fai = file(params.reference_fai)
    reference_dict = file(params.reference_dict)
    known_sites_files = params.known_sites.collect { file(it) }
    known_sites_indices_files = params.known_sites_indices.collect { file(it) }
    dbsnp_vcf_file = file(params.dbsnp_vcf)
    dbsnp_vcf_index_file = file(params.dbsnp_vcf_index)

    BWA_MEM(reads_ch, reference)
    MARK_DUPLICATES(BWA_MEM.out.alignment)

    BASE_RECALIBRATOR(
        MARK_DUPLICATES.out.deduped.map { sample, bam, bai, metrics ->
            tuple(sample, bam, bai)
        },
        reference,
        dbsnp_vcf_file,
        dbsnp_vcf_index_file
    )

    MARK_DUPLICATES.out.deduped
        .join(BASE_RECALIBRATOR.out.recal_table)
        .map { sample, bam, bai, metrics, recal_table ->
            tuple(sample, bam, bai, recal_table)
        }
        .set { apply_bqsr_input }

    APPLY_BQSR(apply_bqsr_input, reference)
    HAPLOTYPE_CALLER(APPLY_BQSR.out.recalibrated, reference, reference_fai, reference_dict)
    VARIANT_FILTER(HAPLOTYPE_CALLER.out.variants, reference, dbsnp_vcf_file, dbsnp_vcf_index_file)
}
