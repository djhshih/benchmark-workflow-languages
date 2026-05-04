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
    "trimmomatic": Tool(
        name="trimmomatic",
        base_command="java -jar trimmomatic.jar",
        inputs={"reads": "array", "adapters": "File"},
        outputs={"trimmed_reads": "*.fastq.gz", "logs": "*_log.txt"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=1024),
    ),
    "star": Tool(
        name="star",
        base_command="STAR",
        inputs={"reads": "array", "reference_index": "Directory"},
        outputs={"alignment": "*.bam", "log": "*.log"},
        resources=Resource(cpu=8, memory_mb=32768, disk_mb=10240),
    ),
    "fastqc": Tool(
        name="fastqc",
        base_command="fastqc",
        inputs={"reads": "array"},
        outputs={"reports": "*.html"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=512),
    ),
    "featurecounts": Tool(
        name="featurecounts",
        base_command="featureCounts",
        inputs={"alignment": "File", "annotation": "File"},
        outputs={"counts": "counts.txt", "summary": "counts.txt.summary"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024),
    ),
}

RNA_PIPELINE = Pipeline(
    name="rna_seq",
    inputs={
        "reads": "array",
        "adapters": "File",
        "reference_index": "Directory",
        "annotation": "File",
    },
    tools=TOOLS,
    steps=[
        Step(id="trim", tool="trimmomatic", inputs={"reads": "inputs.reads", "adapters": "inputs.adapters"}),
        Step(id="align", tool="star", inputs={"reads": "trim.trimmed_reads", "reference_index": "inputs.reference_index"}),
        Step(id="fastqc", tool="fastqc", inputs={"reads": "trim.trimmed_reads"}),
        Step(id="feature_counts", tool="featurecounts", inputs={"alignment": "align.alignment", "annotation": "inputs.annotation"}),
    ],
    outputs={
        "counts": "feature_counts.counts",
        "reports": "fastqc.reports",
    },
)

if __name__ == "__main__":
    print("RNA-seq Pipeline defined with", len(RNA_PIPELINE.steps), "steps")