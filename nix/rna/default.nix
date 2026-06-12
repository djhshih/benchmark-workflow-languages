{ pkgs ? import <nixpkgs> {} }:

let
  Task = name: command: docker: inputs: outputs: resources: {
    inherit name command docker inputs outputs resources;
  };

  trimmomatic = Task "trimmomatic"
    "trimmomatic PE -threads ${toString resources.cpu} ${inputs.reads[0]} ${inputs.reads[1]} ${inputs.sample_name}_R1.trimmed.fastq.gz ${inputs.sample_name}_R1.unpaired.fastq.gz ${inputs.sample_name}_R2.trimmed.fastq.gz ${inputs.sample_name}_R2.unpaired.fastq.gz ILLUMINACLIP:${inputs.adapters}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36"
    "quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7"
    { sample_name = "string"; reads = "array"; adapters = "file"; }
    { trimmed_r1 = "${inputs.sample_name}_R1.trimmed.fastq.gz"; trimmed_r2 = "${inputs.sample_name}_R2.trimmed.fastq.gz"; }
    { cpu = 2; memory = 4096; disk = 5120; };

  star = Task "star"
    "mkdir -p star_${inputs.sample_name} && STAR --runMode alignReads --genomeDir ${inputs.reference_index} --readFilesIn ${inputs.r1} ${inputs.r2} --readFilesCommand zcat --runThreadN ${toString resources.cpu} --outFileNamePrefix star_${inputs.sample_name}/ --outSAMtype BAM SortedByCoordinate --outBAMcompression 1 --outSAMunmapped Within KeepPairs --twopassMode Basic --outSAMattrRGline ID:${inputs.sample_name} LB:${inputs.sample_name} PL:ILLUMINA SM:${inputs.sample_name}"
    "quay.io/biocontainers/star:2.7.3a--0"
    { sample_name = "string"; r1 = "file"; r2 = "file"; reference_index = "directory"; }
    { alignment_bam = "star_${inputs.sample_name}/Aligned.sortedByCoord.out.bam"; log_final = "star_${inputs.sample_name}/Log.final.out"; }
    { cpu = 8; memory = 32768; disk = 20480; };

  fastqc = Task "fastqc"
    "mkdir -p fastqc_${inputs.sample_name} && fastqc --outdir fastqc_${inputs.sample_name} --threads ${toString resources.cpu} ${inputs.r1} ${inputs.r2}"
    "quay.io/biocontainers/fastqc:0.11.9--0"
    { sample_name = "string"; r1 = "file"; r2 = "file"; }
    { html_report_r1 = "fastqc_${inputs.sample_name}/${inputs.sample_name}_R1.trimmed_fastqc.html"; html_report_r2 = "fastqc_${inputs.sample_name}/${inputs.sample_name}_R2.trimmed_fastqc.html"; zip_report_r1 = "fastqc_${inputs.sample_name}/${inputs.sample_name}_R1.trimmed_fastqc.zip"; zip_report_r2 = "fastqc_${inputs.sample_name}/${inputs.sample_name}_R2.trimmed_fastqc.zip"; }
    { cpu = 2; memory = 4096; disk = 2048; };

  featurecounts = Task "featurecounts"
    "featureCounts -T ${toString resources.cpu} -a ${inputs.annotation} -s ${inputs.strand_flag} -o ${inputs.sample_name}_counts.txt ${inputs.alignment}"
    "quay.io/biocontainers/subread:2.0.1--hed695b0_0"
    { sample_name = "string"; alignment = "file"; annotation = "file"; strand_flag = "string"; }
    { counts = "${inputs.sample_name}_counts.txt"; counts_summary = "${inputs.sample_name}_counts.txt.summary"; }
    { cpu = 4; memory = 8192; disk = 5120; };

in {
  name = "rna_seq";

  depends = [ trimmomatic star fastqc featurecounts ];

  inputs = {
    sample_name = "string";
    reads = "array";
    adapters = "file";
    reference_index = "directory";
    reference_fasta = "file";
    annotation = "file";
    strand_flag = "string";
  };

  steps = {
    trim = {
      task = "trimmomatic";
      inputs = {
        sample_name = "sample_name";
        reads = "reads";
        adapters = "adapters";
      };
    };
    align = {
      task = "star";
      inputs = {
        sample_name = "sample_name";
        r1 = "trim.trimmed_r1";
        r2 = "trim.trimmed_r2";
        reference_index = "reference_index";
      };
    };
    qc = {
      task = "fastqc";
      inputs = {
        sample_name = "sample_name";
        r1 = "trim.trimmed_r1";
        r2 = "trim.trimmed_r2";
      };
    };
    counts = {
      task = "featurecounts";
      inputs = {
        sample_name = "sample_name";
        alignment = "align.alignment_bam";
        annotation = "annotation";
        strand_flag = "strand_flag";
      };
    };
  };

  outputs = {
    counts = "counts.counts";
    qc_report_r1 = "qc.html_report_r1";
    qc_report_r2 = "qc.html_report_r2";
  };
}
