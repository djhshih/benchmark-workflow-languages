let lib = import "../../nickel/nixflow/lib/cwl.ncl" in
let dfn = import "../../nickel/nixflow/lib/dfn.ncl" in

let bwa_mem = {
  name = "bwa_mem",
  inputs = {
    reads = "array",
    reference = "File",
  },
  outputs = {
    alignment = "*.sam",
  },
  exec = "bwa mem",
  command = m%"
    bwa mem -t %{cpu} %{reference} %{reads[0]} %{reads[1]} > %{sample_name}.sam
  "%,
  runtime = {
    cpu = 4,
    memory = 8192,
    disk = 1024,
  },
} | dfn.Task in

let sort_bam = {
  name = "sort_bam",
  inputs = {
    alignment = "File",
  },
  outputs = {
    sorted_bam = "*.bam",
  },
  exec = "samtools sort",
  command = m%"
    samtools sort -o sorted.bam %{alignment}
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let index_bam = {
  name = "index_bam",
  inputs = {
    bam = "File",
  },
  outputs = {
    indexed_bam = "*.bai",
  },
  exec = "samtools index",
  command = m%"
    samtools index %{bam}
  "%,
  runtime = {
    cpu = 1,
    memory = 2048,
    disk = 1024,
  },
} | dfn.Task in

let collectreadcounts = {
  name = "collectreadcounts",
  inputs = {
    bam = "File",
    reference = "File",
    intervals = "File",
  },
  outputs = {
    counts = "*.tsv",
  },
  exec = "gatk CollectReadCounts",
  command = m%"
    gatk CollectReadCounts -I %{bam} -R %{reference} -L %{intervals} -O counts.tsv
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let collectgc = {
  name = "collectgc",
  inputs = {
    reference = "File",
    intervals = "File",
  },
  outputs = {
    gc_file = "*.txt",
  },
  exec = "gatk CountGC",
  command = m%"
    gatk CountGC -R %{reference} -L %{intervals} -O gc.txt
  "%,
  runtime = {
    cpu = 1,
    memory = 2048,
    disk = 1024,
  },
} | dfn.Task in

let denoisecoverage = {
  name = "denoisecoverage",
  inputs = {
    counts = "File",
    gc_file = "File",
    reference_panel = "array",
  },
  outputs = {
    denoised_cr = "*.tsv",
  },
  exec = "gatk DenoiseReadCounts",
  command = m%"
    gatk DenoiseReadCounts --count-table %{counts} --gc-curve-file %{gc_file} --reference-panel %{reference_panel[0]} -O denoised_cr
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let segmentcnv = {
  name = "segmentcnv",
  inputs = {
    denoised_cr = "File",
    intervals = "File",
  },
  outputs = {
    segments = "*.tsv",
  },
  exec = "gatk SegmentDenoisedCopyRatios",
  command = m%"
    gatk SegmentDenoisedCopyRatios --denoised-copy-ratios %{denoised_cr} -O segments.tsv
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let callcnv = {
  name = "callcnv",
  inputs = {
    segments = "File",
    sample_name = "string",
  },
  outputs = {
    cnv_calls = "*.vcf",
  },
  exec = "gatk ModelSegments",
  command = m%"
    gatk ModelSegments --denoised-copy-ratios %{segments} -O %{sample_name}_cnv.vcf
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let workflow = {
  name = "cnv_calling",
  depends = [bwa_mem, sort_bam, index_bam, collectreadcounts, collectgc, denoisecoverage, segmentcnv, callcnv],
  steps = {
    align = { task = "bwa_mem", inputs = { reads = "reads", reference = "reference" } },
    sort = { task = "sort_bam", inputs = { alignment = "align.alignment" } },
    index = { task = "index_bam", inputs = { bam = "sort.sorted_bam" } },
    collect_coverage = { task = "collectreadcounts", inputs = { bam = "index.indexed_bam", reference = "reference", intervals = "target_regions" } },
    collect_gc = { task = "collectgc", inputs = { reference = "reference", intervals = "target_regions" } },
    denoise = { task = "denoisecoverage", inputs = { counts = "collect_coverage.counts", gc_file = "collect_gc.gc_file", reference_panel = "reference_panel" } },
    segment = { task = "segmentcnv", inputs = { denoised_cr = "denoise.denoised_cr", intervals = "target_regions" } },
    call_cnv = { task = "callcnv", inputs = { segments = "segment.segments", sample_name = "sample_name" } },
  },
  outputs = {
    cnv_calls = "call_cnv.cnv_calls",
    coverage = "collect_coverage.counts",
  },
} | dfn.Workflow in

{
  bwa_mem,
  sort_bam,
  index_bam,
  collectreadcounts,
  collectgc,
  denoisecoverage,
  segmentcnv,
  callcnv,
  workflow,
}