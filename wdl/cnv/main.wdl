version 1.0

workflow cnv_calling {
    String sample_name
    Array[File] reads
    File reference
    File target_regions
    Array[File] reference_panel

    call bwa_mem {
        input:
            sample_name = sample_name,
            reads = reads,
            reference = reference
    }

    call sort_bam {
        input:
            alignment = bwa_mem.alignment
    }

    call index_bam {
        input:
            bam = sort_bam.sorted_bam
    }

    call collect_read_counts {
        input:
            bam = index_bam.indexed_bam,
            reference = reference,
            intervals = target_regions
    }

    call collect_gc {
        input:
            reference = reference,
            intervals = target_regions
    }

    call denoise_coverage {
        input:
            counts = collect_read_counts.counts,
            gc_file = collect_gc.gc_file,
            reference_panel = reference_panel
    }

    call segment_cnv {
        input:
            denoised_cr = denoise_coverage.denoised_cr,
            intervals = target_regions
    }

    call call_cnv {
        input:
            segments = segment_cnv.segments,
            sample_name = sample_name
    }

    output {
        File cnv_calls = call_cnv.cnv_calls
        File coverage = collect_read_counts.counts
    }
}

task bwa_mem {
    String sample_name
    Array[File] reads
    File reference

    command <<<
        bwa mem -t 4 ~{reference} ~{reads[0]} ~{reads[1]} > ~{sample_name}.sam
    >>>

    runtime {
        cpu: 4
        memory: "8 GB"
    }

    output {
        File alignment = "~{sample_name}.sam"
    }
}

task sort_bam {
    File alignment

    command <<<
        samtools sort -o sorted.bam ~{alignment}
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        File sorted_bam = "sorted.bam"
    }
}

task index_bam {
    File bam

    command <<<
        samtools index ~{bam}
    >>>

    runtime {
        cpu: 1
        memory: "2 GB"
    }

    output {
        File indexed_bam = "~{bam}"
    }
}

task collect_read_counts {
    File bam
    File reference
    File intervals

    command <<<
        gatk CollectReadCounts -I ~{bam} -R ~{reference} -L ~{intervals} -O counts.tsv
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        File counts = "counts.tsv"
    }
}

task collect_gc {
    File reference
    File intervals

    command <<<
        gatk CountGC -R ~{reference} -L ~{intervals} -O gc.txt
    >>>

    runtime {
        cpu: 1
        memory: "2 GB"
    }

    output {
        File gc_file = "gc.txt"
    }
}

task denoise_coverage {
    File counts
    File gc_file
    Array[File] reference_panel

    command <<<
        gatk DenoiseReadCounts --count-table ~{counts} --gc-curve-file ~{gc_file} \
            --reference-panel ~{reference_panel[0]} -O denoised_cr
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        File denoised_cr = "denoised_cr.tsv"
    }
}

task segment_cnv {
    File denoised_cr
    File intervals

    command <<<
        gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ~{denoised_cr} -O segments.tsv
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        File segments = "segments.tsv"
    }
}

task call_cnv {
    File segments
    String sample_name

    command <<<
        gatk ModelSegments --denoised-copy-ratios ~{segments} -O ~{sample_name}_cnv.vcf
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
    }

    output {
        File cnv_calls = "~{sample_name}_cnv.vcf"
    }
}