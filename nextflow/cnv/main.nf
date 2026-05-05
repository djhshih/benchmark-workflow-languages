nextflow.enable.dsl = 2

params.sample_name = null
params.reads = null
params.reference = null
params.target_regions = null
params.reference_panel = []

process BWA_MEM {
    cpus 4
    memory '8 GB'
    disk '1 GB'
    
    input:
        tuple val(sample), path(reads)
        path reference
    
    output:
        path "*.sam", emit: alignment
    
    """
    bwa mem -t ${task.cpus} ${reference} ${reads[0]} ${reads[1]} > ${sample}.sam
    """
}

process SORT_BAM {
    cpus 2
    memory '4 GB'
    disk '1 GB'
    
    input:
        path alignment
    
    output:
        path "sorted.bam", emit: sorted_bam
    
    """
    samtools sort -o sorted.bam ${alignment}
    """
}

process INDEX_BAM {
    cpus 1
    memory '2 GB'
    disk '512 MB'
    
    input:
        path bam
    
    output:
        path "*.bai", emit: indexed_bam
    
    """
    samtools index ${bam}
    """
}

process COLLECT_READ_COUNTS {
    cpus 2
    memory '4 GB'
    disk '1 GB'
    
    input:
        path bam
        path reference
        path intervals
    
    output:
        path "counts.tsv", emit: counts
    
    """
    gatk CollectReadCounts -I ${bam} -R ${reference} -L ${intervals} -O counts.tsv
    """
}

process COLLECT_GC {
    cpus 1
    memory '2 GB'
    disk '512 MB'
    
    input:
        path reference
        path intervals
    
    output:
        path "gc.txt", emit: gc_file
    
    """
    gatk CountGC -R ${reference} -L ${intervals} -O gc.txt
    """
}

process DENOISE_COVERAGE {
    cpus 2
    memory '4 GB'
    disk '2 GB'
    
    input:
        path counts
        path gc_file
        path reference_panel
    
    output:
        path "denoised_cr.tsv", emit: denoised_cr
    
    """
    gatk DenoiseReadCounts --count-table ${counts} --gc-curve-file ${gc_file} \
        --reference-panel ${reference_panel[0]} -O denoised_cr
    """
}

process SEGMENT_CNV {
    cpus 2
    memory '4 GB'
    disk '1 GB'
    
    input:
        path denoised_cr
        path intervals
    
    output:
        path "segments.tsv", emit: segments
    
    """
    gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ${denoised_cr} -O segments.tsv
    """
}

process CALL_CNV {
    cpus 2
    memory '4 GB'
    disk '1 GB'
    
    input:
        path segments
        val sample_name
    
    output:
        path "*.vcf", emit: cnv_calls
    
    """
    gatk ModelSegments --denoised-copy-ratios ${segments} -O ${sample_name}_cnv.vcf
    """
}

workflow {
    reads = Channel.fromFilePairs(params.reads)
    reference = file(params.reference)
    target_regions = file(params.target_regions)
    reference_panel = Channel.fromPath(params.reference_panel)
    sample_name = params.sample_name
    
    BWA_MEM(reads, reference)
    SORT_BAM(BWA_MEM.out.alignment)
    INDEX_BAM(SORT_BAM.out.sorted_bam)
    COLLECT_READ_COUNTS(INDEX_BAM.out.indexed_bam, reference, target_regions)
    COLLECT_GC(reference, target_regions)
    DENOISE_COVERAGE(COLLECT_READ_COUNTS.out.counts, COLLECT_GC.out.gc_file, reference_panel)
    SEGMENT_CNV(DENOISE_COVERAGE.out.denoised_cr, target_regions)
    CALL_CNV(SEGMENT_CNV.out.segments, sample_name)
    
    emit:
        cnv_calls = CALL_CNV.out.cnv_calls
        coverage = COLLECT_READ_COUNTS.out.counts
}