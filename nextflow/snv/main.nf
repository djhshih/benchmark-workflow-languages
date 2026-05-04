nextflow.enable.dsl = 2

params.sample_name = null
params.reads = null
params.reference = null
params.reference_dict = null
params.reference_fai = null
params.known_sites = []

process BWA_MEM {
    cpus 4
    memory '8 GB'
    # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
    # WDL equivalent: cpu: 4, memory: "8 GB"
    # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
    # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    
    input:
        tuple val(sample), path(reads)
        path reference
    
    output:
        path "*.sam", emit: alignment
    
    """
    bwa mem -t ${task.cpus} ${reference} ${reads[0]} ${reads[1]} > ${sample}.sam
    """
}

process MARK_DUPLICATES {
    cpus 2
    memory '4 GB'
    # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
    # WDL equivalent: cpu: 2, memory: "4 GB"
    # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
    # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    
    input:
        path alignment
        val sample_name
    
    output:
        path "deduped.bam", emit: deduped_bam
        path "metrics.txt", emit: metrics
    
    """
    java -jar picard.jar MarkDuplicates I=${alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true
    """
}

process BASE_RECALIBRATOR {
    cpus 2
    memory '4 GB'
    # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
    # WDL equivalent: cpu: 2, memory: "4 GB"
    # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
    # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    
    input:
        path input_bam
        path reference
        path reference_dict
        path known_sites
    
    output:
        path "recal.table", emit: recal_table
        path "report.txt", emit: report
    
    """
    java -jar gatk BaseRecalibrator -I ${input_bam} -R ${reference} \
        --known-sites ${known_sites[0]} --known-sites ${known_sites[1]} \
        -O recal.table -BQSR report.txt
    """
}

process APPLY_BQSR {
    cpus 2
    memory '4 GB'
    # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
    # WDL equivalent: cpu: 2, memory: "4 GB"
    # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
    # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    
    input:
        path input_bam
        path recal_table
        path reference
    
    output:
        path "recalibrated.bam", emit: recalibrated_bam
    
    """
    java -jar gatk ApplyBQSR -I ${input_bam} -R ${reference} --bqsr-recal-file ${recal_table} -O recalibrated.bam
    """
}

process HAPLOTYPE_CALLER {
    cpus 4
    memory '8 GB'
    # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
    # WDL equivalent: cpu: 4, memory: "8 GB"
    # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
    # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    
    input:
        path input_bam
        path reference
        path reference_dict
        path reference_fai
    
    output:
        path "variants.g.vcf", emit: variants
    
    """
    java -jar gatk HaplotypeCaller -I ${input_bam} -R ${reference} -O variants.g.vcf -ERC GVCF
    """
}

process VARIANT_FILTER {
    cpus 4
    memory '8 GB'
    # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
    # WDL equivalent: cpu: 4, memory: "8 GB"
    # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
    # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    
    input:
        path variants
        path reference
    
    output:
        path "filtered.vcf", emit: filtered_variants
    
    """
    java -jar gatk VariantRecalibrator -V ${variants} -R ${reference} -O filtered.vcf \
        --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0
    """
}

workflow {
    reads = Channel.fromFilePairs(params.reads)
    reference = file(params.reference)
    known_sites = Channel.fromPath(params.known_sites)
    sample_name = params.sample_name
    
    BWA_MEM(reads, reference)
    MARK_DUPLICATES(BWA_MEM.out.alignment, sample_name)
    BASE_RECALIBRATOR(MARK_DUPLICATES.out.deduped_bam, reference, reference, known_sites)
    APPLY_BQSR(MARK_DUPLICATES.out.deduped_bam, BASE_RECALIBRATOR.out.recal_table, reference)
    HAPLOTYPE_CALLER(APPLY_BQSR.out.recalibrated_bam, reference, reference, reference)
    VARIANT_FILTER(HAPLOTYPE_CALLER.out.variants, reference)
    
    emit:
        variants = VARIANT_FILTER.out.filtered_variants
        recal_table = BASE_RECALIBRATOR.out.recal_table
}