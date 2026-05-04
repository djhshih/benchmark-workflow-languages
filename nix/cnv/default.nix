{ pkgs ? import <nixpkgs> {} }:

let
  Task = name: command: inputs: outputs: resources: {
    inherit name command inputs outputs resources;
  };

  bwa_mem = Task "bwa-mem"
    "bwa mem -t ${toString resources.cpu} ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]}"
    { reads = "array"; reference = "file"; }
    { alignment = "*.sam"; }
    { cpu = 4; memory = 8192; disk = 1024; };

  sort_bam = Task "sort-bam"
    "samtools sort -@ ${toString resources.cpu} ${inputs.alignment} -o sorted.bam"
    { alignment = "file"; }
    { sorted_bam = "*.bam"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  index_bam = Task "index-bam"
    "samtools index ${inputs.bam}"
    { bam = "file"; }
    { bai = "*.bai"; }
    { cpu = 1; memory = 2048; disk = 512; };

  collect_readcounts = Task "collect-readcounts"
    "python collectreadcounts.py -I ${inputs.bam} -R ${inputs.reference} -o readcounts.hdf5"
    { bam = "file"; reference = "file"; }
    { readcounts = "*.hdf5"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  collect_gc = Task "collect-gc"
    "python collectgc.py -R ${inputs.reference} -o gc.hdf5"
    { reference = "file"; }
    { gc = "*.hdf5"; }
    { cpu = 1; memory = 2048; disk = 512; };

  denoise_coverage = Task "denoise-coverage"
    "python denoisecoverage.py --readcounts ${inputs.readcounts} --gc ${inputs.gc} --output prefix"
    { readcounts = "file"; gc = "file"; }
    { denoised = "*_denoised.hdf5"; }
    { cpu = 4; memory = 8192; disk = 2048; };

  segment_cnv = Task "segment-cnv"
    "python segmentcnv.py --denoised ${inputs.denoised} -o segments.hdf5"
    { denoised = "file"; }
    { segments = "*.hdf5"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  call_cnv = Task "call-cnv"
    "python callcnv.py --segments ${inputs.segments} -o cnv.vcf"
    { segments = "file"; }
    { cnv = "*.vcf"; }
    { cpu = 2; memory = 4096; disk = 1024; };

in {
  name = "cnv_calling";

  depends = [ bwa_mem sort_bam index_bam collect_readcounts collect_gc denoise_coverage segment_cnv call_cnv ];

  inputs = {
    reads = "array";
    reference = "file";
  };

  steps = {
    align = {
      task = "bwa-mem";
      inputs = {
        reads = "reads";
        reference = "reference";
      };
    };
    sort = {
      task = "sort-bam";
      inputs = {
        alignment = "align.alignment";
      };
    };
    index = {
      task = "index-bam";
      inputs = {
        bam = "sort.sorted_bam";
      };
    };
    readcounts = {
      task = "collect-readcounts";
      inputs = {
        bam = "index.bai";
        reference = "reference";
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
      };
    };
    segment = {
      task = "segment-cnv";
      inputs = {
        denoised = "denoise.denoised";
      };
    };
    call = {
      task = "call-cnv";
      inputs = {
        segments = "segment.segments";
      };
    };
  };

  outputs = {
    cnv = "call.cnv";
  };
}