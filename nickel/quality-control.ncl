let lib = import "../../nickel/nixflow/lib/cwl.ncl" in
let dfn = import "../../nickel/nixflow/lib/dfn.ncl" in

let fastqc = {
  name = "fastqc",
  inputs = {
    reads = "array",
  },
  outputs = {
    reports = "*",
  },
  command = m%"
    fastqc %{reads}
  "%,
} | dfn.Task in

let trimmomatic = {
  name = "trimmomatic",
  inputs = {
    reads = "array",
    adapters = "File",
  },
  outputs = {
    trimmed_reads = "*.fastq.gz",
    step_log = "*_log.txt",
  },
  command = m%"
    java -jar trimmomatic.jar PE %{reads[0]} %{reads[1]} 
      trimmed_R1.fastq.gz trimmed_R2.fastq.gz 
      ILLUMINACLIP:adapters.fa:2:30:10 
      LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
  "%,
} | dfn.Task in

let bowtie2 = {
  name = "bowtie2",
  inputs = {
    reads = "array",
    reference_index = "File",
  },
  outputs = {
    sorted_bam = "*.bam",
  },
  command = m%"
    bowtie2 -x %{reference_index} -1 %{reads[0]} -2 %{reads[1]} 
      --threads %{cpu} -S alignment.sam
  "%,
} | dfn.Task in

let workflow = {
  name = "quality-control",
  depends = [fastqc, trimmomatic, bowtie2],
  steps = {
    initial_qc = {
      task = "fastqc",
      inputs = { reads = "reads" },
    },
    trim = {
      task = "trimmomatic",
      inputs = {
        reads = "reads",
        adapters = "adapters",
      },
    },
    post_qc = {
      task = "fastqc",
      inputs = { reads = "trim.trimmed_reads" },
    },
    align = {
      task = "bowtie2",
      inputs = {
        reads = "trim.trimmed_reads",
        reference_index = "reference_index",
      },
    },
  },
  outputs = {
    trimmed_reports = "trim.step_log",
    alignment = "align.sorted_bam",
    qc_reports = "post_qc.reports",
  },
} | dfn.Workflow in

{
  fastqc,
  trimmomatic,
  bowtie2,
  workflow,
}