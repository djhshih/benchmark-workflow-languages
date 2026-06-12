nextflow.enable.dsl = 2

params.sample_name = "sample"
params.reads = null
params.reference_fasta = null
params.reference_fasta_fai = null
params.platform = "ont"
params.preset = "map-ont"
params.clair3_model = "r941_prom_sup_g5014"
params.outdir = './results'

process MINIMAP2_MAP {
    container 'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'
    publishDir "${params.outdir}/alignment", mode: 'copy'
    cpus 8
    memory '24 GB'
    disk '10 GB'

    input:
        val(sample)
        path(reads)
        path(reference_fasta)

    output:
        tuple val(sample), path("${sample}.sorted.bam"), path("${sample}.sorted.bam.bai"), emit: alignment

    """
    minimap2 -a -x ${params.preset} -t ${task.cpus} -y \\
        -R "@RG\\tID:${sample}\\tSM:${sample}\\tPL:${params.platform}" \\
        ${reference_fasta} ${reads} | \\
    samtools sort --threads 2 -m 1G -o ${sample}.sorted.bam -
    samtools index ${sample}.sorted.bam
    """
}

process MOSDEPTH_COV {
    container 'quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1'
    publishDir "${params.outdir}/coverage", mode: 'copy'
    cpus 4
    memory '4 GB'
    disk '2 GB'

    input:
        tuple val(sample), path(bam), path(bai)

    output:
        tuple val(sample), path("${sample}.mosdepth.mosdepth.summary.txt"), path("${sample}.mosdepth.mosdepth.global.dist.txt"), emit: coverage

    """
    mosdepth --threads ${task.cpus} --no-per-base ${sample}.mosdepth ${bam}
    """
}

process CLAIR3_CALL {
    container 'quay.io/biocontainers/clair3:1.1.0--py39hd649744_0'
    publishDir "${params.outdir}/variants", mode: 'copy'
    cpus 8
    memory '24 GB'
    disk '20 GB'

    input:
        tuple val(sample), path(bam), path(bai)
        path(reference_fasta)
        path(reference_fasta_fai)

    output:
        tuple val(sample), path("${sample}.clair3.vcf.gz"), path("${sample}.clair3.vcf.gz.tbi"), emit: variants

    """
    run_clair3.sh \\
        --model=${params.clair3_model} \\
        --ref_fn=${reference_fasta} \\
        --bam_fn=${bam} \\
        --output=clair3_out \\
        --threads=${task.cpus} \\
        --platform=${params.platform} \\
        --sample_name=${sample}
    mv clair3_out/merge_output.vcf.gz ${sample}.clair3.vcf.gz
    mv clair3_out/merge_output.vcf.gz.tbi ${sample}.clair3.vcf.gz.tbi
    rm -rf clair3_out
    """
}

process BCFTOOLS_STATS {
    container 'quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2'
    publishDir "${params.outdir}/stats", mode: 'copy'
    cpus 1
    memory '256 MB'
    disk '1 GB'

    input:
        tuple val(sample), path(vcf), path(tbi)

    output:
        tuple val(sample), path("${sample}.vcf.stats"), emit: stats

    """
    bcftools stats ${vcf} > ${sample}.vcf.stats
    """
}

process MULTIQC_REPORT {
    container 'quay.io/biocontainers/multiqc:1.28--pyhdf78af_0'
    publishDir "${params.outdir}/multiqc", mode: 'copy'
    cpus 1
    memory '2 GB'
    disk '1 GB'

    input:
        val(sample)
        path(coverage_summary)
        path(vcf_stats)

    output:
        path("${sample}_multiqc/multiqc_report.html"), emit: report

    """
    mkdir -p ${sample}_multiqc
    multiqc --force --outdir ${sample}_multiqc ${coverage_summary} ${vcf_stats}
    """
}

workflow {
    reads_ch = Channel.fromPath(params.reads)
    reference = file(params.reference_fasta)
    reference_fai = file(params.reference_fasta_fai)

    sample_reads = Channel.value(params.sample_name).combine(reads_ch)

    MINIMAP2_MAP(sample_reads, reference)

    MOSDEPTH_COV(MINIMAP2_MAP.out.alignment)

    CLAIR3_CALL(MINIMAP2_MAP.out.alignment, reference, reference_fai)

    BCFTOOLS_STATS(CLAIR3_CALL.out.variants)

    MOSDEPTH_COV.out.coverage
        .map { sample, summary, dist -> [sample, summary] }
        .join(BCFTOOLS_STATS.out.stats)
        .set { reports_ch }

    MULTIQC_REPORT(
        reports_ch.map { it[0] },
        reports_ch.map { it[1] },
        reports_ch.map { it[2] }
    )
}
