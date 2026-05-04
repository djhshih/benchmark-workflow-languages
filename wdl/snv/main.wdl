version 1.0

workflow snv_calling {
    String sample_name
    Array[File] reads
    File reference
    File reference_dict
    File reference_fai
    Array[File] known_sites

    call bwa_mem {
        input:
            sample_name = sample_name,
            reads = reads,
            reference = reference
    }

    call mark_duplicates {
        input:
            alignment = bwa_mem.alignment,
            sample_name = sample_name
    }

    call base_recalibrator {
        input:
            input_bam = mark_duplicates.deduped_bam,
            reference = reference,
            reference_dict = reference_dict,
            known_sites = known_sites
    }

    call apply_bqsr {
        input:
            input_bam = mark_duplicates.deduped_bam,
            recal_table = base_recalibrator.recal_table,
            reference = reference
    }

    call haplotype_caller {
        input:
            input_bam = apply_bqsr.recalibrated_bam,
            reference = reference,
            reference_dict = reference_dict,
            reference_fai = reference_fai
    }

    call variant_filter {
        input:
            variants = haplotype_caller.variants,
            reference = reference
    }

    output {
        File variants = variant_filter.filtered_variants
        File recal_table = base_recalibrator.recal_table
        File alignment = mark_duplicates.deduped_bam
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
        # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
        # Nextflow equivalent: cpus 4, memory '8 GB'
        # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
        # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    }

    output {
        File alignment = "~{sample_name}.sam"
    }
}

task mark_duplicates {
    File alignment
    String sample_name

    command <<<
        java -jar picard.jar MarkDuplicates I=~{alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
        # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
        # Nextflow equivalent: cpus 2, memory '4 GB'
        # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
        # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    }

    output {
        File deduped_bam = "deduped.bam"
        File metrics = "metrics.txt"
    }
}

task base_recalibrator {
    File input_bam
    File reference
    File reference_dict
    Array[File] known_sites

    command <<<
        java -jar gatk BaseRecalibrator -I ~{input_bam} -R ~{reference} \
            --known-sites ~{known_sites[0]} --known-sites ~{known_sites[1]} \
            -O recal.table -BQSR report.txt
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
        # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
        # Nextflow equivalent: cpus 2, memory '4 GB'
        # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
        # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    }

    output {
        File recal_table = "recal.table"
        File report = "report.txt"
    }
}

task apply_bqsr {
    File input_bam
    File recal_table
    File reference

    command <<<
        java -jar gatk ApplyBQSR -I ~{input_bam} -R ~{reference} --bqsr-recal-file ~{recal_table} -O recalibrated.bam
    >>>

    runtime {
        cpu: 2
        memory: "4 GB"
        # CWL equivalent: coresMin: 2, ramMin: 4096, outdirMin: 1024
        # Nextflow equivalent: cpus 2, memory '4 GB'
        # Python equivalent: cpu=2, memory_mb=4096, disk_mb=1024
        # Nickel equivalent: cpu = 2, memory = 4096, disk = 1024
    }

    output {
        File recalibrated_bam = "recalibrated.bam"
    }
}

task haplotype_caller {
    File input_bam
    File reference
    File reference_dict
    File reference_fai

    command <<<
        java -jar gatk HaplotypeCaller -I ~{input_bam} -R ~{reference} -O variants.g.vcf -ERC GVCF
    >>>

    runtime {
        cpu: 4
        memory: "8 GB"
        # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
        # Nextflow equivalent: cpus 4, memory '8 GB'
        # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
        # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    }

    output {
        File variants = "variants.g.vcf"
    }
}

task variant_filter {
    File variants
    File reference

    command <<<
        java -jar gatk VariantRecalibrator -V ~{variants} -R ~{reference} -O filtered.vcf \
            --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0
    >>>

    runtime {
        cpu: 4
        memory: "8 GB"
        # CWL equivalent: coresMin: 4, ramMin: 8192, outdirMin: 1024
        # Nextflow equivalent: cpus 4, memory '8 GB'
        # Python equivalent: cpu=4, memory_mb=8192, disk_mb=1024
        # Nickel equivalent: cpu = 4, memory = 8192, disk = 1024
    }

    output {
        File filtered_variants = "filtered.vcf"
    }
}