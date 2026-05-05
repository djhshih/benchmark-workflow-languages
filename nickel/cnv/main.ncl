let
  Task = name: command: inputs: outputs: resources: {
    inherit name command inputs outputs resources;
  };

  bwa_mem = Task "bwa-mem"
    "bwa mem -t ${toString resources.cpu} ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]}"
    { reads = "array"; reference = "file"; sample_name = "string"; }
    { alignment = "${sample_name}.sam"; }
    { cpu = 4; memory = 8192; disk = 1024; };

  sort_bam = Task "sort-bam"
    "samtools sort -@ ${toString resources.cpu} ${inputs.alignment} -o ${sample_name}_sorted.bam"
    { alignment = "file"; sample_name = "string"; }
    { sorted_bam = "${sample_name}_sorted.bam"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  index_bam = Task "index-bam"
    "samtools index ${inputs.bam}"
    { bam = "file"; sample_name = "string"; }
    { bai = "${sample_name}_sorted.bam.bai"; }
    { cpu = 1; memory = 2048; disk = 512; };

  collect_readcounts = Task "collect-readcounts"
    "gatk CollectReadCounts -I ${inputs.bam} -R ${inputs.reference} -O ${sample_name}_readcounts.tsv"
    { bam = "file"; reference = "file"; sample_name = "string"; }
    { readcounts = "${sample_name}_readcounts.tsv"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  collect_gc = Task "collect-gc"
    "gatk CountGC -R ${inputs.reference} -O gc.tsv"
    { reference = "file"; }
    { gc = "gc.tsv"; }
    { cpu = 1; memory = 2048; disk = 512; };

  denoise_coverage = Task "denoise-coverage"
    "gatk DenoiseReadCounts --readcounts ${inputs.readcounts} --gc-hdf5 ${inputs.gc} --output-prefix ${sample_name}"
    { readcounts = "file"; gc = "file"; sample_name = "string"; }
    { denoised = "${sample_name}_denoised.tsv"; }
    { cpu = 4; memory = 8192; disk = 2048; };

  segment_cnv = Task "segment-cnv"
    "gatk SegmentDenoisedCopyRatios --denoised ${inputs.denoised} -O ${sample_name}_segments.tsv"
    { denoised = "file"; sample_name = "string"; }
    { segments = "${sample_name}_segments.tsv"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  call_cnv = Task "call-cnv"
    "gatk ModelSegments --segments ${inputs.segments} -O ${sample_name}_cnv.vcf"
    { segments = "file"; sample_name = "string"; }
    { cnv = "${sample_name}_cnv.vcf"; }
    { cpu = 2; memory = 4096; disk = 1024; };

in {
  name = "cnv_calling";

  depends = [ bwa_mem sort_bam index_bam collect_readcounts collect_gc denoise_coverage segment_cnv call_cnv ];

  inputs = {
    sample_name = "string";
    reads = "array";
    reference = "file";
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
    sort = {
      task = "sort-bam";
      inputs = {
        alignment = "align.alignment";
        sample_name = "sample_name";
      };
    };
    index = {
      task = "index-bam";
      inputs = {
        bam = "sort.sorted_bam";
        sample_name = "sample_name";
      };
    };
    readcounts = {
      task = "collect-readcounts";
      inputs = {
        bam = "index.bai";
        reference = "reference";
        sample_name = "sample_name";
      };
    };
    gc = {
      task = "collect-gc";
      inputs = {
        reference = "reference";
      };
    };
    denoise = {
      task = "denoise-coverage";
      inputs = {
        readcounts = "readcounts.readcounts";
        gc = "gc.gc";
        sample_name = "sample_name";
      };
    };
    segment = {
      task = "segment-cnv";
      inputs = {
        denoised = "denoise.denoised";
        sample_name = "sample_name";
      };
    };
    call = {
      task = "call-cnv";
      inputs = {
        segments = "segment.segments";
        sample_name = "sample_name";
      };
    };
  };

  outputs = {
    cnv = "call.cnv";
  };
}