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
    "sort_bam": Tool(
        name="sort_bam",
        base_command="samtools sort",
        inputs={"alignment": "File"},
        outputs={"sorted_bam": "*.bam"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "index_bam": Tool(
        name="index_bam",
        base_command="samtools index",
        inputs={"bam": "File"},
        outputs={"indexed_bam": "*.bai"},
        resources=Resource(cpu=1, memory_mb=2048, disk_mb=1024),
    ),
    "collectreadcounts": Tool(
        name="collectreadcounts",
        base_command="gatk CollectReadCounts",
        inputs={"bam": "File", "reference": "File", "intervals": "File"},
        outputs={"counts": "*.tsv"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "collectgc": Tool(
        name="collectgc",
        base_command="gatk CountGC",
        inputs={"reference": "File", "intervals": "File"},
        outputs={"gc_file": "*.txt"},
        resources=Resource(cpu=1, memory_mb=2048, disk_mb=1024),
    ),
    "denoisecoverage": Tool(
        name="denoisecoverage",
        base_command="gatk DenoiseReadCounts",
        inputs={"counts": "File", "gc_file": "File", "reference_panel": "array"},
        outputs={"denoised_cr": "*.tsv"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "segmentcnv": Tool(
        name="segmentcnv",
        base_command="gatk SegmentDenoisedCopyRatios",
        inputs={"denoised_cr": "File", "intervals": "File"},
        outputs={"segments": "*.tsv"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "callcnv": Tool(
        name="callcnv",
        base_command="gatk ModelSegments",
        inputs={"segments": "File", "sample_name": "string"},
        outputs={"cnv_calls": "*.vcf"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
}

CNV_PIPELINE = Pipeline(
    name="cnv_calling",
    inputs={
        "sample_name": "string",
        "reads": "array",
        "reference": "File",
        "target_regions": "File",
        "reference_panel": "array",
    },
    tools=TOOLS,
    steps=[
        Step(id="align", tool="bwa_mem", inputs={"reads": "inputs.reads", "reference": "inputs.reference"}),
        Step(id="sort", tool="sort_bam", inputs={"alignment": "align.alignment"}),
        Step(id="index", tool="index_bam", inputs={"bam": "sort.sorted_bam"}),
        Step(id="collect_coverage", tool="collectreadcounts", inputs={"bam": "index.indexed_bam", "reference": "inputs.reference", "intervals": "inputs.target_regions"}),
        Step(id="collect_gc", tool="collectgc", inputs={"reference": "inputs.reference", "intervals": "inputs.target_regions"}),
        Step(id="denoise", tool="denoisecoverage", inputs={"counts": "collect_coverage.counts", "gc_file": "collect_gc.gc_file", "reference_panel": "inputs.reference_panel"}),
        Step(id="segment", tool="segmentcnv", inputs={"denoised_cr": "denoise.denoised_cr", "intervals": "inputs.target_regions"}),
        Step(id="call_cnv", tool="callcnv", inputs={"segments": "segment.segments", "sample_name": "inputs.sample_name"}),
    ],
    outputs={
        "cnv_calls": "call_cnv.cnv_calls",
        "coverage": "collect_coverage.counts",
    },
)

if __name__ == "__main__":
    print("CNV Pipeline defined with", len(CNV_PIPELINE.steps), "steps")