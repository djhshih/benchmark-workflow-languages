let
  lib = import ./cwl.nix;

  fastqc = lib.mkTask {
    name = "fastqc";
    inputs = {
      reads = "array";
    };
    outputs = {
      reports = ["File" "*.html"];
    };
    command = ''
      fastqc ${concatStringsSep " " (map (r: "${r}") inputs.reads)}
    '';
    runtime = {
      cpu = 1;
      memory = 2048;
      disk = 1024;
    };
  };

  trimmomatic = lib.mkTask {
    name = "trimmomatic";
    inputs = {
      reads = "array";
      adapters = "File";
    };
    outputs = {
      trimmed_reads = ["File" "*.fastq.gz"];
      step_log = ["File" "*_log.txt"];
    };
    command = ''
      java -jar trimmomatic.jar PE ${builtins.elemAt inputs.reads 0} ${builtins.elemAt inputs.reads 1} 
        trimmed_R1.fastq.gz trimmed_R2.fastq.gz 
        ILLUMINACLIP:adapters.fa:2:30:10 
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    '';
    runtime = {
      cpu = 2;
      memory = 4096;
      disk = 2048;
    };
  };

  bowtie2 = lib.mkTask {
    name = "bowtie2";
    inputs = {
      reads = "array";
      reference_index = "File";
    };
    outputs = {
      sorted_bam = ["File" "*.bam"];
    };
    command = ''
      bowtie2 -x ${inputs.reference_index} -1 ${builtins.elemAt inputs.reads 0} -2 ${builtins.elemAt inputs.reads 1} 
        --threads ${toString runtime.cpu} -S alignment.sam
    '';
    runtime = {
      cpu = 4;
      memory = 8192;
      disk = 5120;
    };
  };

  workflow = lib.mkWorkflow {
    name = "quality-control";
    inputs = {
      reads = "array";
      reference_index = "File";
      adapters = "File";
    };
    outputs = {
      trimmed_reports = ["File" "trim.step_log"];
      alignment = ["File" "align.sorted_bam"];
      qc_reports = ["File" "post_qc.reports"];
    };
    depends = [fastqc trimmomatic bowtie2];
    steps = {
      initial_qc = {
        task = "fastqc";
        inputs = {
          reads = "reads";
        };
      };
      trim = {
        task = "trimmomatic";
        inputs = {
          reads = "reads";
          adapters = "adapters";
        };
      };
      post_qc = {
        task = "fastqc";
        inputs = {
          reads = "trim.trimmed_reads";
        };
      };
      align = {
        task = "bowtie2";
        inputs = {
          reads = "trim.trimmed_reads";
          reference_index = "reference_index";
        };
      };
    };
  };

in {
  inherit fastqc trimmomatic bowtie2 workflow;
}