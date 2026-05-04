#!/usr/bin/env python3
"""
Common Subset: A minimal DSL that can transpile to CWL, Nextflow, and WDL.

The idea: Define a pipeline once in a minimal declarative format,
then transpile to any target.
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
import json


@dataclass
class ResourceRequirement:
    cpu: int = 1
    memory_mb: int = 2048
    disk_mb: int = 1024


@dataclass
class Tool:
    name: str
    base_command: str
    inputs: Dict[str, str] = field(default_factory=dict)
    outputs: Dict[str, str] = field(default_factory=dict)
    resources: ResourceRequirement = field(default_factory=ResourceRequirement)


@dataclass
class Pipeline:
    name: str
    inputs: Dict[str, str] = field(default_factory=dict)
    tools: Dict[str, Tool] = field(default_factory=dict)
    steps: List[Dict[str, Any]] = field(default_factory=list)
    outputs: Dict[str, str] = field(default_factory=dict)


# Example: Define the pipeline
PIPELINE = Pipeline(
    name="quality-control",
    inputs={
        "reads": "File",
        "reference_index": "File",
        "adapters": "File",
    },
    tools={
        "fastqc": Tool(
            name="fastqc",
            base_command="fastqc",
            inputs={"reads": "File"},
            outputs={"reports": "*.html"},
            resources=ResourceRequirement(cpu=1, memory_mb=2048),
        ),
        "trimmomatic": Tool(
            name="trimmomatic",
            base_command="java -jar trimmomatic.jar PE",
            inputs={"reads": "File", "adapters": "File"},
            outputs={"trimmed": "*.fastq.gz", "log": "*_log.txt"},
            resources=ResourceRequirement(cpu=2, memory_mb=4096),
        ),
        "bowtie2": Tool(
            name="bowtie2",
            base_command="bowtie2",
            inputs={"reads": "File", "reference_index": "File"},
            outputs={"alignment": "*.sam"},
            resources=ResourceRequirement(cpu=4, memory_mb=8192),
        ),
    },
    steps=[
        {"id": "qc1", "tool": "fastqc", "inputs": {"reads": "inputs.reads"}},
        {"id": "trim", "tool": "trimmomatic", "inputs": {"reads": "inputs.reads", "adapters": "inputs.adapters"}},
        {"id": "qc2", "tool": "fastqc", "inputs": {"reads": "trim.trimmed"}},
        {"id": "align", "tool": "bowtie2", "inputs": {"reads": "trim.trimmed", "reference_index": "inputs.reference_index"}},
    ],
    outputs={
        "trimmed_reports": "trim.log",
        "alignment": "align.alignment",
        "qc_reports": "qc2.reports",
    },
)


def to_cwl(pipeline: Pipeline) -> Dict[str, Any]:
    """Transpile to CWL."""
    cwl = {
        "cwlVersion": "v1.0",
        "class": "Workflow",
        "inputs": [{"id": k, "type": v} for k, v in pipeline.inputs.items()],
        "outputs": [{"id": k, "type": "File", "outputSource": v} for k, v in pipeline.outputs.items()],
        "steps": [],
    }

    for step in pipeline.steps:
        tool = pipeline.tools[step["tool"]]
        cwl["steps"].append({
            "id": step["id"],
            "run": f"{tool.name}.cwl",
            "in": {k: v.split(".")[-1] for k, v in step["inputs"].items()},
            "out": list(tool.outputs.keys()),
        })

    return cwl


def to_nextflow(pipeline: Pipeline) -> str:
    """Transpile to Nextflow DSL2."""
    code = []
    code.append("nextflow.enable.dsl = 2\n")

    # Process definitions
    for tool_name, tool in pipeline.tools.items():
        code.append(f'''
process {tool_name.upper()} {{
    cpus {tool.resources.cpu}
    memory '{tool.resources.memory_mb} MB'
    
    input:
        path reads
    
    output:
        path "{list(tool.outputs.values())[0]}", emit: out
    
    """
    {tool.base_command} $reads
    """
}}
''')

    # Workflow definition
    code.append("\nworkflow {\n")
    for step in pipeline.steps:
        code.append(f"    {step['tool'].upper()}({step['inputs']['reads']})\n")
    code.append("}\n")

    return "".join(code)


def to_wdl(pipeline: Pipeline) -> str:
    """Transpile to WDL."""
    wdl = ["version 1.0", f"\nworkflow {pipeline.name} {{"]

    # Inputs
    for name, type_ in pipeline.inputs.items():
        wdl.append(f"    File {name}")

    # Task calls
    for step in pipeline.steps:
        wdl.append(f"\n    call {step['tool']} {{")
        for inp, src in step["inputs"].items():
            wdl.append(f"        input: {inp} = {src}")
        wdl.append("    }")

    # Outputs
    wdl.append("\n    output {")
    for name, source in pipeline.outputs.items():
        wdl.append(f"        File {name} = {source}")
    wdl.append("    }\n}")

    # Tasks
    for tool_name, tool in pipeline.tools.items():
        wdl.append(f"""
task {tool_name} {{
    input:
        File reads
    
    command <<<
        {tool.base_command} ${{reads}}
    >>>
    
    runtime {{
        cpu: {tool.resources.cpu}
        memory: "{tool.resources.memory_mb} MB"
    }}
    
    output {{
        File out = glob("*")[0]
    }}
}}""")

    return "\n".join(wdl)


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: common-subset.py [cwl|nf|wdl]")
        sys.exit(1)

    target = sys.argv[1]

    if target == "cwl":
        print(json.dumps(to_cwl(PIPELINE), indent=2))
    elif target == "nf":
        print(to_nextflow(PIPELINE))
    elif target == "wdl":
        print(to_wdl(PIPELINE))