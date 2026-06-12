{ pkgs ? import <nixpkgs> {} }:

let
  Task = name: command: docker: inputs: outputs: resources: {
    inherit name command docker inputs outputs resources;
  };

  minimap2_map = Task "minimap2_map"
    "minimap2 -a -x ${inputs.preset} -t ${toString resources.cpu} -y -R \"@RG\\tID:${inputs.sample_name}\\tSM:${inputs.sample_name}\\tPL:${inputs.platform}\" ${inputs.reference_fasta} ${inputs.reads} | samtools sort --threads 2 -m 1G -o ${inputs.sample_name}.sorted.bam - && samtools index ${inputs.sample_name}.sorted.bam"
    "quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0"
    { sample_name = "string"; reads = "file"; reference_fasta = "file"; preset = "string"; platform = "string"; }
    { sorted_bam = "${inputs.sample_name}.sorted.bam"; sorted_bam_index = "${inputs.sample_name}.sorted.bam.bai"; }
    { cpu = 8; memory = 24576; disk = 10240; };

  mosdepth_cov = Task "mosdepth_cov"
    "mosdepth --threads ${toString resources.cpu} --no-per-base ${inputs.sample_name}.mosdepth ${inputs.bam}"
    "quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1"
    { bam = "file"; sample_name = "string"; }
    { mosdepth_global = "${inputs.sample_name}.mosdepth.mosdepth.global.dist.txt"; mosdepth_per_region = "${inputs.sample_name}.mosdepth.mosdepth.region.dist.txt"; mosdepth_summary = "${inputs.sample_name}.mosdepth.mosdepth.summary.txt"; }
    { cpu = 4; memory = 4096; disk = 2048; };

  clair3_call = Task "clair3_call"
    "run_clair3.sh --model=${inputs.model} --ref_fn=${inputs.ref_fasta} --bam_fn=${inputs.bam} --output=clair3_out --threads=${toString resources.cpu} --platform=${inputs.platform} --sample_name=${inputs.sample_name} && mv clair3_out/merge_output.vcf.gz ${inputs.sample_name}.clair3.vcf.gz && mv clair3_out/merge_output.vcf.gz.tbi ${inputs.sample_name}.clair3.vcf.gz.tbi && rm -rf clair3_out"
    "quay.io/biocontainers/clair3:1.1.0--py39hd649744_0"
    { bam = "file"; ref_fasta = "file"; reference_fasta_fai = "file"; model = "string"; platform = "string"; sample_name = "string"; }
    { clair3_vcf = "${inputs.sample_name}.clair3.vcf.gz"; clair3_vcf_index = "${inputs.sample_name}.clair3.vcf.gz.tbi"; }
    { cpu = 8; memory = 24576; disk = 20480; };

  bcftools_stats = Task "bcftools_stats"
    "bcftools stats ${inputs.input_vcf} > ${inputs.sample_name}.vcf.stats"
    "quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2"
    { input_vcf = "file"; sample_name = "string"; }
    { vcf_stats = "${inputs.sample_name}.vcf.stats"; }
    { cpu = 1; memory = 1024; disk = 512; };

  multiqc_report = Task "multiqc_report"
    "multiqc --force --outdir ${inputs.sample_name}_multiqc ${inputs.mosdepth_summary} ${inputs.vcf_stats}"
    "quay.io/biocontainers/multiqc:1.28--pyhdfd78af_0"
    { mosdepth_summary = "file"; vcf_stats = "file"; sample_name = "string"; }
    { multiqc_dir = "${inputs.sample_name}_multiqc"; }
    { cpu = 1; memory = 2048; disk = 512; };

in {
  name = "long_read_calling";

  depends = [ minimap2_map mosdepth_cov clair3_call bcftools_stats multiqc_report ];

  inputs = {
    sample_name = "string";
    reads = "file";
    reference_fasta = "file";
    reference_fasta_fai = "file";
    preset = "string";
    platform = "string";
    model = "string";
  };

  steps = {
    align = {
      task = "minimap2_map";
      inputs = {
        sample_name = "sample_name";
        reads = "reads";
        reference_fasta = "reference_fasta";
        preset = "preset";
        platform = "platform";
      };
    };
    coverage = {
      task = "mosdepth_cov";
      inputs = {
        bam = "align.sorted_bam";
        sample_name = "sample_name";
      };
    };
    variant_call = {
      task = "clair3_call";
      inputs = {
        bam = "align.sorted_bam";
        ref_fasta = "reference_fasta";
        reference_fasta_fai = "reference_fasta_fai";
        model = "model";
        platform = "platform";
        sample_name = "sample_name";
      };
    };
    stats = {
      task = "bcftools_stats";
      inputs = {
        input_vcf = "variant_call.clair3_vcf";
        sample_name = "sample_name";
      };
    };
    report = {
      task = "multiqc_report";
      inputs = {
        mosdepth_summary = "coverage.mosdepth_summary";
        vcf_stats = "stats.vcf_stats";
        sample_name = "sample_name";
      };
    };
  };

  outputs = {
    sorted_bam = "align.sorted_bam";
    clair3_vcf = "variant_call.clair3_vcf";
    vcf_stats = "stats.vcf_stats";
    multiqc_dir = "report.multiqc_dir";
  };
}
