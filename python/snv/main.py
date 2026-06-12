from dataclasses import dataclass, field
from typing import Dict, List

@dataclass
class Resource:
    cpu: int = 1
    memory_mb: int = 2048
    disk_mb: int = 1024

@dataclass
class Tool:
    name: str
    base_command: str
    docker_image: str = ""
    inputs: Dict[str, str] = field(default_factory=dict)
    outputs: Dict[str, str] = field(default_factory=dict)
    resources: Resource = field(default_factory=Resource)

@dataclass
class Step:
    id: str
    tool: str
    inputs: Dict[str, str] = field(default_factory=dict)

@dataclass
class Pipeline:
    name: str
    inputs: Dict[str, str] = field(default_factory=dict)
    tools: Dict[str, Tool] = field(default_factory=dict)
    steps: List[Step] = field(default_factory=list)
    outputs: Dict[str, str] = field(default_factory=dict)

GATK_DOCKER = "quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0"
BWA_DOCKER = "quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0"
PICARD_DOCKER = "quay.io/biocontainers/picard:3.3.0--hdfd78af_0"

TOOLS = {
    "bwa_mem": Tool(
        name="bwa_mem",
        base_command='bwa mem -t {cpu} -R "@RG\\tID:{sample}\\tLB:1\\tPL:ILLUMINA\\tSM:{sample}" {reference} {reads_0} {reads_1} 2> {sample}.bwa.log | samtools sort -@ {cpu_minus_1} -m 2G -o {sample}.sorted.bam - && samtools index {sample}.sorted.bam',
        docker_image=BWA_DOCKER,
        inputs={"sample_name": "string", "reads": "array", "reference": "File", "reference_fai": "File"},
        outputs={"output_bam": "{sample}.sorted.bam", "output_bam_index": "{sample}.sorted.bam.bai", "bwa_log": "{sample}.bwa.log"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=10240),
    ),
    "mark_duplicates": Tool(
        name="mark_duplicates",
        base_command='picard -Xmx6656M -XX:ParallelGCThreads=1 MarkDuplicates INPUT={input_bam} OUTPUT={sample}.deduped.bam METRICS_FILE={sample}.deduped.metrics.txt CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CLEAR_DT=false',
        docker_image=PICARD_DOCKER,
        inputs={"input_bam": "File", "input_bam_index": "File", "sample_name": "string"},
        outputs={"deduped_bam": "{sample}.deduped.bam", "deduped_bam_index": "{sample}.deduped.bai", "metrics": "{sample}.deduped.metrics.txt"},
        resources=Resource(cpu=2, memory_mb=7168, disk_mb=10240),
    ),
    "base_recalibrator": Tool(
        name="base_recalibrator",
        base_command='gatk --java-options "-Xmx1024M -XX:ParallelGCThreads=1" BaseRecalibrator -R {ref} -I {bam} --use-original-qualities -O {sample}.recal.table --known-sites {sites_0} --known-sites {dbsnp}',
        docker_image=GATK_DOCKER,
        inputs={"input_bam": "File", "input_bam_index": "File", "sample_name": "string", "reference": "File", "reference_dict": "File", "reference_fai": "File", "known_sites": "array", "known_sites_indices": "array", "dbsnp_vcf": "File", "dbsnp_vcf_index": "File"},
        outputs={"recal_table": "{sample}.recal.table"},
        resources=Resource(cpu=2, memory_mb=1536, disk_mb=5120),
    ),
    "apply_bqsr": Tool(
        name="apply_bqsr",
        base_command='gatk --java-options "-Xmx2048M -XX:ParallelGCThreads=1" ApplyBQSR --create-output-bam-md5 --add-output-sam-program-record -R {ref} -I {bam} --use-original-qualities -O {sample}.recalibrated.bam -bqsr {table} --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30',
        docker_image=GATK_DOCKER,
        inputs={"input_bam": "File", "sample_name": "string", "reference": "File", "reference_fai": "File", "recal_table": "File"},
        outputs={"recalibrated_bam": "{sample}.recalibrated.bam", "recalibrated_bam_index": "{sample}.recalibrated.bai", "recalibrated_bam_md5": "{sample}.recalibrated.bam.md5"},
        resources=Resource(cpu=2, memory_mb=2560, disk_mb=10240),
    ),
    "haplotype_caller": Tool(
        name="haplotype_caller",
        base_command='gatk --java-options "-Xmx4096M -XX:ParallelGCThreads=1" HaplotypeCaller -R {ref} -I {bam} -O {sample}.g.vcf.gz --emit-ref-confidence GVCF',
        docker_image=GATK_DOCKER,
        inputs={"input_bam": "File", "sample_name": "string", "reference": "File", "reference_fai": "File"},
        outputs={"output_vcf": "{sample}.g.vcf.gz", "output_vcf_index": "{sample}.g.vcf.gz.tbi"},
        resources=Resource(cpu=4, memory_mb=4608, disk_mb=10240),
    ),
    "variant_filter": Tool(
        name="variant_filter",
        base_command='gatk --java-options "-Xmx8192M -XX:ParallelGCThreads=1" VariantRecalibrator -R {ref} -V {vcf} --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 {dbsnp} -O {sample}.variant_filter.vcf.gz --tranches-file {sample}.tranches --rscript-file {sample}.plots.R --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4',
        docker_image=GATK_DOCKER,
        inputs={"input_vcf": "File", "sample_name": "string", "reference": "File", "reference_fai": "File", "dbsnp_vcf": "File", "dbsnp_vcf_index": "File"},
        outputs={"filtered_vcf": "{sample}.variant_filter.vcf.gz", "filtered_vcf_index": "{sample}.variant_filter.vcf.gz.tbi", "tranches": "{sample}.tranches", "r_script": "{sample}.plots.R"},
        resources=Resource(cpu=4, memory_mb=8704, disk_mb=5120),
    ),
}

SNV_PIPELINE = Pipeline(
    name="snv_calling",
    inputs={
        "sample_name": "string",
        "reads": "array",
        "reference": "File",
        "reference_dict": "File",
        "reference_fai": "File",
        "known_sites": "array",
        "known_sites_indices": "array",
        "dbsnp_vcf": "File",
        "dbsnp_vcf_index": "File",
    },
    tools=TOOLS,
    steps=[
        Step(id="align", tool="bwa_mem", inputs={"reads": "inputs.reads", "reference": "inputs.reference", "reference_fai": "inputs.reference_fai", "sample_name": "inputs.sample_name"}),
        Step(id="markdup", tool="mark_duplicates", inputs={"input_bam": "align.output_bam", "input_bam_index": "align.output_bam_index", "sample_name": "inputs.sample_name"}),
        Step(id="baserecal", tool="base_recalibrator", inputs={"input_bam": "markdup.deduped_bam", "input_bam_index": "markdup.deduped_bam_index", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_dict": "inputs.reference_dict", "reference_fai": "inputs.reference_fai", "known_sites": "inputs.known_sites", "known_sites_indices": "inputs.known_sites_indices", "dbsnp_vcf": "inputs.dbsnp_vcf", "dbsnp_vcf_index": "inputs.dbsnp_vcf_index"}),
        Step(id="apply", tool="apply_bqsr", inputs={"input_bam": "markdup.deduped_bam", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_fai": "inputs.reference_fai", "recal_table": "baserecal.recal_table"}),
        Step(id="haplotype", tool="haplotype_caller", inputs={"input_bam": "apply.recalibrated_bam", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_fai": "inputs.reference_fai"}),
        Step(id="filter", tool="variant_filter", inputs={"input_vcf": "haplotype.output_vcf", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_fai": "inputs.reference_fai", "dbsnp_vcf": "inputs.dbsnp_vcf", "dbsnp_vcf_index": "inputs.dbsnp_vcf_index"}),
    ],
    outputs={
        "filtered_vcf": "filter.filtered_vcf",
        "recal_table": "baserecal.recal_table",
    },
)

if __name__ == "__main__":
    print("SNV Pipeline defined with", len(SNV_PIPELINE.steps), "steps")
