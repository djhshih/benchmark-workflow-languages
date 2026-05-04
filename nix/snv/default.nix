{ pkgs ? import <nixpkgs> {} }:

let
  Resource = { cpu, memory, disk }: {
    inherit cpu memory disk;
  };

  Task = name: command: inputs: outputs: resources: {
    inherit name command inputs outputs resources;
  };

  bwa_mem = Task "bwa-mem"
    "bwa mem -t ${toString resources.cpu} ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]}"
    { reads = "array"; reference = "file"; sample_name = "string"; }
    { alignment = "*.sam"; }
    { cpu = 4; memory = 8192; disk = 1024; };

  markduplicates = Task "markduplicates"
    "java -jar picard.jar MarkDuplicates I=${inputs.alignment} O=deduped.bam M=metrics.txt"
    { alignment = "file"; sample_name = "string"; }
    { deduped_bam = "*.bam"; metrics = "*.txt"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  baserecalibrator = Task "baserecalibrator"
    "java -jar gatk BaseRecalibrator -I ${inputs.input} -R ${inputs.reference} -O recal.table"
    { input = "file"; reference = "file"; known_sites = "array"; }
    { recal_table = "*.table"; report = "*.txt"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  applybqsr = Task "applybqsr"
    "java -jar gatk ApplyBQSR -I ${inputs.input} -R ${inputs.reference} --bqsr-recal-file ${inputs.recal_table} -O recalibrated.bam"
    { input = "file"; recal_table = "file"; reference = "file"; }
    { recalibrated_bam = "*.bam"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  haplotypecaller = Task "haplotypecaller"
    "java -jar gatk HaplotypeCaller -I ${inputs.input} -R ${inputs.reference} -O variants.g.vcf"
    { input = "file"; reference = "file"; }
    { variants = "*.vcf"; }
    { cpu = 4; memory = 8192; disk = 1024; };

  variantfilter = Task "variantfilter"
    "java -jar gatk VariantRecalibrator -V ${inputs.variants} -R ${inputs.reference} -O filtered.vcf"
    { variants = "file"; reference = "file"; }
    { filtered_variants = "*.vcf"; }
    { cpu = 4; memory = 8192; disk = 1024; };

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
  };

  steps = {
    align = {
      task = "bwa-mem";
      inputs = {
        reads = "reads";
        reference = "reference";
        sample_name = "sample_name";
      };
    };
    markdup = {
      task = "markduplicates";
      inputs = {
        alignment = "align.alignment";
        sample_name = "sample_name";
      };
    };
    baserecal = {
      task = "baserecalibrator";
      inputs = {
        input = "markdup.deduped_bam";
        reference = "reference";
        known_sites = "known_sites";
      };
    };
    applybqsr = {
      task = "applybqsr";
      inputs = {
        input = "markdup.deduped_bam";
        recal_table = "baserecal.recal_table";
        reference = "reference";
      };
    };
    haplotype = {
      task = "haplotypecaller";
      inputs = {
        input = "applybqsr.recalibrated_bam";
        reference = "reference";
      };
    };
    filter = {
      task = "variantfilter";
      inputs = {
        variants = "haplotype.variants";
        reference = "reference";
      };
    };
  };

  outputs = {
    variants = "filter.filtered_variants";
    recal_table = "baserecal.recal_table";
  };
}