let
  Resource = {
    cpu | Number,
    memory | Number,
    disk | Number,
  };

  TaskDef = {
    name | String,
    command | String,
    docker | String,
    inputs | {_: Dyn},
    outputs | {_: Dyn},
    resources | Resource,
  };

  Task = fun name => fun command => fun docker => fun inputs => fun outputs => fun resources =>
    {
      name,
      command,
      docker,
      inputs,
      outputs,
      resources,
    }
  in

  bwa_mem = Task
    "bwa_mem"
    "bwa mem -t ${to_string resources.cpu} -R \"@RG\\tID:${inputs.sample_name}\\tLB:1\\tPL:ILLUMINA\\tSM:${inputs.sample_name}\" ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]} 2> ${inputs.sample_name}.bwa.log | samtools sort -@ ${to_string (resources.cpu - 1)} -m 2G -o ${inputs.sample_name}.sorted.bam - && samtools index ${inputs.sample_name}.sorted.bam"
    "quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0"
    { sample_name = "string"; reads = "array"; reference = "file"; }
    { output_bam = "${inputs.sample_name}.sorted.bam"; output_bam_index = "${inputs.sample_name}.sorted.bam.bai"; bwa_log = "${inputs.sample_name}.bwa.log"; }
    { cpu = 4; memory = 8192; disk = 10240; };

  markduplicates = Task
    "mark_duplicates"
    "picard MarkDuplicates INPUT=${inputs.input_bam} OUTPUT=${inputs.sample_name}.deduped.bam METRICS_FILE=${inputs.sample_name}.deduped.metrics.txt CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CLEAR_DT=false"
    "quay.io/biocontainers/picard:3.3.0--hdfd78af_0"
    { input_bam = "file"; input_bam_index = "file"; sample_name = "string"; }
    { deduped_bam = "${inputs.sample_name}.deduped.bam"; deduped_bam_index = "${inputs.sample_name}.deduped.bai"; metrics = "${inputs.sample_name}.deduped.metrics.txt"; }
    { cpu = 2; memory = 7168; disk = 10240; };

  baserecalibrator = Task
    "base_recalibrator"
    "gatk --java-options \"-Xmx1024M -XX:ParallelGCThreads=1\" BaseRecalibrator --use-original-qualities -I ${inputs.input_bam} -R ${inputs.reference} --known-sites ${inputs.dbsnp_vcf} -O ${inputs.sample_name}.recal.table"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_bam = "file"; input_bam_index = "file"; sample_name = "string"; reference = "file"; reference_dict = "file"; reference_fai = "file"; known_sites = "array"; dbsnp_vcf = "file"; }
    { recal_table = "${inputs.sample_name}.recal.table"; }
    { cpu = 2; memory = 1536; disk = 5120; };

  applybqsr = Task
    "apply_bqsr"
    "gatk --java-options \"-Xmx2048M -XX:ParallelGCThreads=1\" ApplyBQSR --create-output-bam-md5 --add-output-sam-program-record -R ${inputs.reference} -I ${inputs.input_bam} --use-original-qualities -O ${inputs.sample_name}.recalibrated.bam -bqsr ${inputs.recal_table} --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_bam = "file"; sample_name = "string"; reference = "file"; reference_fai = "file"; recal_table = "file"; }
    { recalibrated_bam = "${inputs.sample_name}.recalibrated.bam"; recalibrated_bam_index = "${inputs.sample_name}.recalibrated.bai"; recalibrated_bam_md5 = "${inputs.sample_name}.recalibrated.bam.md5"; }
    { cpu = 2; memory = 2560; disk = 10240; };

  haplotypecaller = Task
    "haplotype_caller"
    "gatk --java-options \"-Xmx4096M -XX:ParallelGCThreads=1\" HaplotypeCaller -R ${inputs.reference} -I ${inputs.input_bam} -O ${inputs.sample_name}.g.vcf.gz --emit-ref-confidence GVCF"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_bam = "file"; sample_name = "string"; reference = "file"; reference_fai = "file"; }
    { output_vcf = "${inputs.sample_name}.g.vcf.gz"; output_vcf_index = "${inputs.sample_name}.g.vcf.gz.tbi"; }
    { cpu = 4; memory = 4608; disk = 10240; };

  variantfilter = Task
    "variant_filter"
    "gatk --java-options \"-Xmx8192M -XX:ParallelGCThreads=1\" VariantRecalibrator -R ${inputs.reference} -V ${inputs.input_vcf} --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 ${inputs.dbsnp_vcf} -O ${inputs.sample_name}.variant_filter.vcf.gz --tranches-file ${inputs.sample_name}.tranches --rscript-file ${inputs.sample_name}.plots.R --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_vcf = "file"; input_vcf_index = "file"; sample_name = "string"; reference = "file"; reference_fai = "file"; dbsnp_vcf = "file"; dbsnp_vcf_index = "file"; }
    { filtered_vcf = "${inputs.sample_name}.variant_filter.vcf.gz"; filtered_vcf_index = "${inputs.sample_name}.variant_filter.vcf.gz.tbi"; tranches = "${inputs.sample_name}.tranches"; r_script = "${inputs.sample_name}.plots.R"; }
    { cpu = 4; memory = 8704; disk = 5120; };

in {
  name = "snv_calling";

  depends = [ bwa_mem markduplicates baserecalibrator applybqsr haplotypecaller variantfilter ];

  inputs = {
    sample_name = "string";
    reads = "array";
    reference = "file";
    reference_dict = "file";
    reference_fai = "file";
    known_sites = "array";
    dbsnp_vcf = "file";
    dbsnp_vcf_index = "file";
  };

  steps = {
    align = {
      task = "bwa_mem";
      inputs = {
        reads = "reads";
        reference = "reference";
        sample_name = "sample_name";
      };
    };
    markdup = {
      task = "mark_duplicates";
      inputs = {
        input_bam = "align.output_bam";
        input_bam_index = "align.output_bam_index";
        sample_name = "sample_name";
      };
    };
    baserecal = {
      task = "base_recalibrator";
      inputs = {
        input_bam = "markdup.deduped_bam";
        input_bam_index = "markdup.deduped_bam_index";
        sample_name = "sample_name";
        reference = "reference";
        reference_dict = "reference_dict";
        reference_fai = "reference_fai";
        known_sites = "known_sites";
        dbsnp_vcf = "dbsnp_vcf";
      };
    };
    apply = {
      task = "apply_bqsr";
      inputs = {
        input_bam = "markdup.deduped_bam";
        sample_name = "sample_name";
        reference = "reference";
        reference_fai = "reference_fai";
        recal_table = "baserecal.recal_table";
      };
    };
    haplotype = {
      task = "haplotype_caller";
      inputs = {
        input_bam = "apply.recalibrated_bam";
        sample_name = "sample_name";
        reference = "reference";
        reference_fai = "reference_fai";
      };
    };
    filter = {
      task = "variant_filter";
      inputs = {
        input_vcf = "haplotype.output_vcf";
        input_vcf_index = "haplotype.output_vcf_index";
        sample_name = "sample_name";
        reference = "reference";
        reference_fai = "reference_fai";
        dbsnp_vcf = "dbsnp_vcf";
        dbsnp_vcf_index = "dbsnp_vcf_index";
      };
    };
  };

  outputs = {
    filtered_vcf = "filter.filtered_vcf";
    recal_table = "baserecal.recal_table";
  };
}
