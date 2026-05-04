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

TOOLS = {
    "bwa_mem": Tool(
        name="bwa_mem",
        base_command="bwa mem",
        inputs={"reads": "File", "reference": "File"},
        outputs={"alignment": "*.sam"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024),
    ),
    "markduplicates": Tool(
        name="markduplicates",
        base_command="java -jar picard.jar MarkDuplicates",
        inputs={"alignment": "File", "sample_name": "string"},
        outputs={"deduped_bam": "*.bam", "metrics": "*.txt"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "baserecalibrator": Tool(
        name="baserecalibrator",
        base_command="java -jar gatk BaseRecalibrator",
        inputs={"input": "File", "reference": "File", "known_sites": "array"},
        outputs={"recal_table": "*.table", "report": "*.txt"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "applybqsr": Tool(
        name="applybqsr",
        base_command="java -jar gatk ApplyBQSR",
        inputs={"input": "File", "recal_table": "File", "reference": "File"},
        outputs={"recalibrated_bam": "*.bam"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "haplotypecaller": Tool(
        name="haplotypecaller",
        base_command="java -jar gatk HaplotypeCaller",
        inputs={"input": "File", "reference": "File"},
        outputs={"variants": "*.vcf"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024),
    ),
    "variantfilter": Tool(
        name="variantfilter",
        base_command="java -jar gatk VariantRecalibrator",
        inputs={"variants": "File", "reference": "File"},
        outputs={"filtered_variants": "*.vcf"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024),
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
    },
    tools=TOOLS,
    steps=[
        Step(id="align", tool="bwa_mem", inputs={"reads": "inputs.reads", "reference": "inputs.reference"}),
        Step(id="mark_duplicates", tool="markduplicates", inputs={"alignment": "align.alignment", "sample_name": "inputs.sample_name"}),
        Step(id="base_recal", tool="baserecalibrator", inputs={"input": "mark_duplicates.deduped_bam", "reference": "inputs.reference", "known_sites": "inputs.known_sites"}),
        Step(id="apply_recal", tool="applybqsr", inputs={"input": "mark_duplicates.deduped_bam", "recal_table": "base_recal.recal_table", "reference": "inputs.reference"}),
        Step(id="variant_call", tool="haplotypecaller", inputs={"input": "apply_recal.recalibrated_bam", "reference": "inputs.reference"}),
        Step(id="variant_filter", tool="variantfilter", inputs={"variants": "variant_call.variants", "reference": "inputs.reference"}),
    ],
    outputs={
        "variants": "variant_filter.filtered_variants",
        "recal_table": "base_recal.recal_table",
    },
)

if __name__ == "__main__":
    print("SNV Pipeline defined with", len(SNV_PIPELINE.steps), "steps")