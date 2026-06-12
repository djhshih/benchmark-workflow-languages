{ pkgs ? import <nixpkgs> {} }:

let
  Task = name: command: docker: inputs: outputs: resources: {
    inherit name command docker inputs outputs resources;
  };

  bwa_mem = Task "bwa_mem"
    "bwa mem -t ${toString resources.cpu} -R \"@RG\\tID:${inputs.sample_name}\\tLB:1\\tPL:ILLUMINA\\tSM:${inputs.sample_name}\" ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]} 2> ${inputs.sample_name}.bwa.log | samtools sort -@ ${toString (resources.cpu - 1)} -m 2G -o ${inputs.sample_name}.sorted.bam - && samtools index ${inputs.sample_name}.sorted.bam"
    "quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0"
    { sample_name = "string"; reads = "array"; reference = "file"; }
    { output_bam = "${inputs.sample_name}.sorted.bam"; output_bam_index = "${inputs.sample_name}.sorted.bam.bai"; bwa_log = "${inputs.sample_name}.bwa.log"; }
    { cpu = 4; memory = 8192; disk = 10240; };

  sort_bam = Task "sort_bam"
    "samtools sort -@ ${toString resources.cpu} -m 4G -o ${inputs.sample_name}.coordinate_sorted.bam -T ${inputs.sample_name}.tmp ${inputs.input_bam} && samtools index ${inputs.sample_name}.coordinate_sorted.bam"
    "quay.io/biocontainers/samtools:1.21--h96c455f_1"
    { input_bam = "file"; sample_name = "string"; }
    { sorted_bam = "${inputs.sample_name}.coordinate_sorted.bam"; sorted_bam_index = "${inputs.sample_name}.coordinate_sorted.bam.bai"; }
    { cpu = 2; memory = 4096; disk = 10240; };

  index_bam = Task "index_bam"
    "samtools index ${inputs.input_bam}"
    "quay.io/biocontainers/samtools:1.21--h96c455f_1"
    { input_bam = "file"; sample_name = "string"; }
    { bam_index = "${inputs.sample_name}.coordinate_sorted.bam.bai"; }
    { cpu = 1; memory = 2048; disk = 2048; };

  collect_allelic_counts = Task "collect_allelic_counts"
    "gatk --java-options \"-Xmx10G -XX:ParallelGCThreads=1\" CollectAllelicCounts -L ${inputs.known_sites} -I ${inputs.input_bam} -R ${inputs.reference} -O ${inputs.sample_name}.allelic_counts.tsv"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_bam = "file"; sample_name = "string"; reference = "file"; reference_dict = "file"; reference_fai = "file"; known_sites = "file"; known_sites_index = "file"; }
    { allelic_counts = "${inputs.sample_name}.allelic_counts.tsv"; }
    { cpu = 2; memory = 10240; disk = 5120; };

  collect_read_counts = Task "collect_read_counts"
    "gatk --java-options \"-Xmx7G -XX:ParallelGCThreads=1\" CollectReadCounts -L ${inputs.intervals} -I ${inputs.input_bam} -R ${inputs.reference} --format HDF5 --interval-merging-rule OVERLAPPING_ONLY -O ${inputs.sample_name}.read_counts.hdf5"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { input_bam = "file"; sample_name = "string"; reference = "file"; reference_dict = "file"; reference_fai = "file"; intervals = "file"; }
    { read_counts = "${inputs.sample_name}.read_counts.hdf5"; }
    { cpu = 2; memory = 7168; disk = 5120; };

  denoise_read_counts = Task "denoise_read_counts"
    ("gatk --java-options \"-Xmx4G -XX:ParallelGCThreads=1\" DenoiseReadCounts -I ${inputs.read_counts} "
    + (if inputs.panel_of_normals != "" then "--count-panel-of-normals ${inputs.panel_of_normals} " else "")
    + "--standardized-copy-ratios ${inputs.sample_name}.standardizedCR.tsv --denoised-copy-ratios ${inputs.sample_name}.denoisedCR.tsv")
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { read_counts = "file"; sample_name = "string"; panel_of_normals = "string"; }
    { denoised_cr = "${inputs.sample_name}.denoisedCR.tsv"; standardized_cr = "${inputs.sample_name}.standardizedCR.tsv"; }
    { cpu = 2; memory = 4096; disk = 2048; };

  model_segments = Task "model_segments"
    "gatk --java-options \"-Xmx4G -XX:ParallelGCThreads=1\" ModelSegments --denoised-copy-ratios ${inputs.denoised_cr} --allelic-counts ${inputs.allelic_counts} --output-prefix ${inputs.sample_name}. -O ."
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { denoised_cr = "file"; standardized_cr = "file"; allelic_counts = "file"; sample_name = "string"; }
    { model_segments = "${inputs.sample_name}.modelFinal.seg"; copy_ratio_segments = "${inputs.sample_name}.cr.seg"; allelic_segments = "${inputs.sample_name}.af.seg"; }
    { cpu = 2; memory = 4096; disk = 5120; };

  call_copy_ratio_segments = Task "call_copy_ratio_segments"
    "gatk --java-options \"-Xmx2G -XX:ParallelGCThreads=1\" CallCopyRatioSegments -I ${inputs.segments} -O ${inputs.sample_name}.called.seg"
    "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
    { segments = "file"; sample_name = "string"; }
    { called_segments = "${inputs.sample_name}.called.seg"; }
    { cpu = 1; memory = 2048; disk = 2048; };

in {
  name = "cnv_calling";

  depends = [ bwa_mem sort_bam index_bam collect_allelic_counts collect_read_counts denoise_read_counts model_segments call_copy_ratio_segments ];

  inputs = {
    sample_name = "string";
    reads = "array";
    reference = "file";
    reference_dict = "file";
    reference_fai = "file";
    known_sites = "file";
    known_sites_index = "file";
    intervals = "file";
    panel_of_normals = "string";
  };

  steps = {
    align = {
      task = "bwa_mem";
      inputs = {
        sample_name = "sample_name";
        reads = "reads";
        reference = "reference";
      };
    };
    sort = {
      task = "sort_bam";
      inputs = {
        input_bam = "align.output_bam";
        sample_name = "sample_name";
      };
    };
    index = {
      task = "index_bam";
      inputs = {
        input_bam = "sort.sorted_bam";
        sample_name = "sample_name";
      };
    };
    allelic_counts = {
      task = "collect_allelic_counts";
      inputs = {
        input_bam = "sort.sorted_bam";
        sample_name = "sample_name";
        reference = "reference";
        reference_dict = "reference_dict";
        reference_fai = "reference_fai";
        known_sites = "known_sites";
        known_sites_index = "known_sites_index";
      };
    };
    read_counts = {
      task = "collect_read_counts";
      inputs = {
        input_bam = "sort.sorted_bam";
        sample_name = "sample_name";
        reference = "reference";
        reference_dict = "reference_dict";
        reference_fai = "reference_fai";
        intervals = "intervals";
      };
    };
    denoise = {
      task = "denoise_read_counts";
      inputs = {
        read_counts = "read_counts.read_counts";
        sample_name = "sample_name";
        panel_of_normals = "panel_of_normals";
      };
    };
    model = {
      task = "model_segments";
      inputs = {
        denoised_cr = "denoise.denoised_cr";
        standardized_cr = "denoise.standardized_cr";
        allelic_counts = "allelic_counts.allelic_counts";
        sample_name = "sample_name";
      };
    };
    call = {
      task = "call_copy_ratio_segments";
      inputs = {
        segments = "model.copy_ratio_segments";
        sample_name = "sample_name";
      };
    };
  };

  outputs = {
    called_segments = "call.called_segments";
  };
}
