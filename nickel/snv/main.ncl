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

let markduplicates = {
  name = "markduplicates",
  inputs = {
    alignment = "File",
    sample_name = "string",
  },
  outputs = {
    deduped_bam = "*.bam",
    metrics = "*.txt",
  },
  exec = "java -jar picard.jar MarkDuplicates",
  command = m%"
    java -jar picard.jar MarkDuplicates I=%{alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let baserecalibrator = {
  name = "baserecalibrator",
  inputs = {
    input = "File",
    reference = "File",
    known_sites = "array",
  },
  outputs = {
    recal_table = "*.table",
    report = "*.txt",
  },
  exec = "java -jar gatk BaseRecalibrator",
  command = m%"
    java -jar gatk BaseRecalibrator -I %{input} -R %{reference} --known-sites %{known_sites[0]} -O recal.table
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let applybqsr = {
  name = "applybqsr",
  inputs = {
    input = "File",
    recal_table = "File",
    reference = "File",
  },
  outputs = {
    recalibrated_bam = "*.bam",
  },
  exec = "java -jar gatk ApplyBQSR",
  command = m%"
    java -jar gatk ApplyBQSR -I %{input} -R %{reference} --bqsr-recal-file %{recal_table} -O recalibrated.bam
  "%,
  runtime = {
    cpu = 2,
    memory = 4096,
    disk = 1024,
  },
} | dfn.Task in

let haplotypecaller = {
  name = "haplotypecaller",
  inputs = {
    input = "File",
    reference = "File",
  },
  outputs = {
    variants = "*.vcf",
  },
  exec = "java -jar gatk HaplotypeCaller",
  command = m%"
    java -jar gatk HaplotypeCaller -I %{input} -R %{reference} -O variants.g.vcf -ERC GVCF
  "%,
  runtime = {
    cpu = 4,
    memory = 8192,
    disk = 1024,
  },
} | dfn.Task in

let variantfilter = {
  name = "variantfilter",
  inputs = {
    variants = "File",
    reference = "File",
  },
  outputs = {
    filtered_variants = "*.vcf",
  },
  exec = "java -jar gatk VariantRecalibrator",
  command = m%"
    java -jar gatk VariantRecalibrator -V %{variants} -R %{reference} -O filtered.vcf
  "%,
  runtime = {
    cpu = 4,
    memory = 8192,
    disk = 1024,
  },
} | dfn.Task in

let workflow = {
  name = "snv_calling",
  depends = [bwa_mem, markduplicates, baserecalibrator, applybqsr, haplotypecaller, variantfilter],
  steps = {
    align = { task = "bwa_mem", inputs = { reads = "reads", reference = "reference" } },
    mark_duplicates = { task = "markduplicates", inputs = { alignment = "align.alignment", sample_name = "sample_name" } },
    base_recal = { task = "baserecalibrator", inputs = { input = "mark_duplicates.deduped_bam", reference = "reference", known_sites = "known_sites" } },
    apply_recal = { task = "applybqsr", inputs = { input = "mark_duplicates.deduped_bam", recal_table = "base_recal.recal_table", reference = "reference" } },
    variant_call = { task = "haplotypecaller", inputs = { input = "apply_recal.recalibrated_bam", reference = "reference" } },
    variant_filter = { task = "variantfilter", inputs = { variants = "variant_call.variants", reference = "reference" } },
  },
  outputs = {
    variants = "variant_filter.filtered_variants",
    recal_table = "base_recal.recal_table",
  },
} | dfn.Workflow in

{
  bwa_mem,
  markduplicates,
  baserecalibrator,
  applybqsr,
  haplotypecaller,
  variantfilter,
  workflow,
}