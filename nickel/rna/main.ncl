let
  Task = name: command: inputs: outputs: resources: {
    inherit name command inputs outputs resources;
  };

  trimmomatic = Task "trimmomatic"
    "java -jar trimmomatic.jar PE ${inputs.reads[0]} ${inputs.reads[1]} trimmed_${sample_name}_R1.fastq.gz trimmed_${sample_name}_R2.fastq.gz ILLUMINACLIP:${inputs.adapters}:2:30:10"
    { reads = "array"; adapters = "file"; sample_name = "string"; }
    { trimmed_reads = "trimmed_${sample_name}_*.fastq.gz"; logs = "*_log.txt"; }
    { cpu = 2; memory = 4096; disk = 1024; };

  star = Task "star"
    "STAR --runMode alignReads --runThreadN ${toString resources.cpu} --genomeDir ${inputs.reference_index} --readFilesIn ${inputs.reads[0]} ${inputs.reads[1]} --outFileNamePrefix ${sample_name}_"
    { reads = "array"; reference_index = "directory"; sample_name = "string"; }
    { alignment = "${sample_name}_Aligned.sorted.bam"; log = "${sample_name}*.log"; }
    { cpu = 8; memory = 32768; disk = 10240; };

  fastqc = Task "fastqc"
    "fastqc --outdir . ${inputs.reads[0]} ${inputs.reads[1]}"
    { reads = "array"; sample_name = "string"; }
    { reports = "${sample_name}_*.html"; }
    { cpu = 2; memory = 4096; disk = 512; };

  featurecounts = Task "featurecounts"
    "featureCounts -T ${toString resources.cpu} -a ${inputs.annotation} -o ${sample_name}_counts.txt ${inputs.alignment}"
    { alignment = "file"; annotation = "file"; sample_name = "string"; }
    { counts = "${sample_name}_counts.txt"; summary = "${sample_name}_counts.txt.summary"; }
    { cpu = 4; memory = 8192; disk = 1024; };

in {
  name = "rna_seq";

  depends = [ trimmomatic star fastqc featurecounts ];

  inputs = {
    sample_name = "string";
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
        sample_name = "sample_name";
      };
    };
    align = {
      task = "star";
      inputs = {
        reads = "trim.trimmed_reads";
        reference_index = "reference_index";
        sample_name = "sample_name";
      };
    };
    qc = {
      task = "fastqc";
      inputs = {
        reads = "trim.trimmed_reads";
        sample_name = "sample_name";
      };
    };
    counts = {
      task = "featurecounts";
      inputs = {
        alignment = "align.alignment";
        annotation = "annotation";
        sample_name = "sample_name";
      };
    };
  };

  outputs = {
    counts = "counts.counts";
    reports = "qc.reports";
  };
}