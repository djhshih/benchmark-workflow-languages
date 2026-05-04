let
  Task = name: command: inputs: outputs: resources: {
    inherit name command inputs outputs resources;
  };

  trimmomatic = Task "trimmomatic"
    "java -jar trimmomatic.jar PE ${inputs.reads[0]} ${inputs.reads[1]} trimmed_R1.fastq.gz trimmed_R2.fastq.gz ILLUMINACLIP:${inputs.adapters}:2:30:10"
    { reads = "array"; adapters = "file"; }
    { trimmed_reads = "*.fastq.gz"; logs = "*_log.txt"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  star = Task "star"
    "STAR --runMode alignReads --runThreadN ${toString resources.cpu} --genomeDir ${inputs.reference_index} --readFilesIn ${inputs.reads[0]} ${inputs.reads[1]} --outFileNamePrefix ./"
    { reads = "array"; reference_index = "directory"; }
    { alignment = "*.bam"; log = "*.log"; }
    { cpu = 8; memory = 32768; disk = 10240; };

  fastqc = Task "fastqc"
    "fastqc --outdir . ${inputs.reads[0]} ${inputs.reads[1]}"
    { reads = "array"; }
    { reports = "*.html"; }
    { cpu = 2; memory = 4096; disk = 512; };

  featurecounts = Task "featurecounts"
    "featureCounts -T ${toString resources.cpu} -a ${inputs.annotation} -o counts.txt ${inputs.alignment}"
    { alignment = "file"; annotation = "file"; }
    { counts = "counts.txt"; summary = "counts.txt.summary"; }
    { cpu = 4; memory = 8192; disk = 1024; };

in {
  name = "rna_seq";

  depends = [ trimmomatic star fastqc featurecounts ];

  inputs = {
    reads = "array";
    adapters = "file";
    reference_index = "directory";
    annotation = "file";
  };

  steps = {
    trim = {
      task = "trimmomatic";
      inputs = {
        reads = "reads";
        adapters = "adapters";
      };
    };
    align = {
      task = "star";
      inputs = {
        reads = "trim.trimmed_reads";
        reference_index = "reference_index";
      };
    };
    qc = {
      task = "fastqc";
      inputs = {
        reads = "trim.trimmed_reads";
      };
    };
    counts = {
      task = "featurecounts";
      inputs = {
        alignment = "align.alignment";
        annotation = "annotation";
      };
    };
  };

  outputs = {
    counts = "counts.counts";
    reports = "qc.reports";
  };
}