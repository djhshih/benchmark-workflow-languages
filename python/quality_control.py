#!/usr/bin/env python3
"""Quality control and trimming pipeline in Python."""

from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
from pathlib import Path
import json


@dataclass
class Tool:
    name: str
    base_command: str
    inputs: Dict[str, Any]
    outputs: Dict[str, Any]
    resources: Dict[str, int] = field(default_factory=dict)
    command_template: str = ""


@dataclass
class Task:
    name: str
    tool: Tool
    input_bindings: Dict[str, str]
    output_aliases: Dict[str, str] = field(default_factory=dict)


@dataclass
class Workflow:
    name: str
    inputs: Dict[str, Any]
    outputs: Dict[str, Any]
    tasks: List[Task]
    dependencies: List[str] = field(default_factory=list)


# Define tools
FASTQC = Tool(
    name="fastqc",
    base_command="fastqc",
    inputs={"reads": "array"},
    outputs={"reports": "*.html"},
    resources={"cpu": 1, "memory": 2048, "disk": 1024},
)

TRIMMOMATIC = Tool(
    name="trimmomatic",
    base_command="java -jar trimmomatic.jar",
    inputs={"reads": "array", "adapters": "File"},
    outputs={"trimmed_reads": "*.fastq.gz", "step_log": "*_log.txt"},
    resources={"cpu": 2, "memory": 4096, "disk": 2048},
)

BOWTIE2 = Tool(
    name="bowtie2",
    base_command="bowtie2",
    inputs={"reads": "array", "reference_index": "File"},
    outputs={"sorted_bam": "*.bam"},
    resources={"cpu": 4, "memory": 8192, "disk": 5120},
)


# Define tasks
def make_tasks():
    return {
        "initial_qc": Task(
            name="initial_qc",
            tool=FASTQC,
            input_bindings={"reads": "reads"},
            output_aliases={"reports": "reports"},
        ),
        "trim": Task(
            name="trim",
            tool=TRIMMOMATIC,
            input_bindings={"reads": "reads", "adapters": "adapters"},
            output_aliases={"trimmed_reads": "trimmed_reads", "step_log": "step_log"},
        ),
        "post_qc": Task(
            name="post_qc",
            tool=FASTQC,
            input_bindings={"reads": "trim.trimmed_reads"},
            output_aliases={"reports": "reports"},
        ),
        "align": Task(
            name="align",
            tool=BOWTIE2,
            input_bindings={"reads": "trim.trimmed_reads", "reference_index": "reference_index"},
            output_aliases={"sorted_bam": "sorted_bam"},
        ),
    }


# Define workflow
WORKFLOW = Workflow(
    name="quality-control",
    inputs={
        "reads": {"type": "array", "items": "File"},
        "reference_index": "File",
        "adapters": "File",
    },
    outputs={
        "trimmed_reports": {"type": "array", "items": "File", "source": "trim.step_log"},
        "alignment": {"type": "File", "source": "align.sorted_bam"},
        "qc_reports": {"type": "array", "items": "File", "source": "post_qc.reports"},
    },
    tasks=list(make_tasks().values()),
)


def generate_cwl(workflow: Workflow) -> Dict[str, Any]:
    """Generate CWL from workflow definition."""
    cwl = {
        "cwlVersion": "v1.0",
        "class": "Workflow",
        "inputs": {},
        "outputs": {},
        "steps": {},
    }

    # Process inputs
    for name, spec in workflow.inputs.items():
        if isinstance(spec, dict):
            cwl["inputs"][name] = {"type": spec.get("type", "File")}
        else:
            cwl["inputs"][name] = {"type": spec}

    # Process outputs
    for name, spec in workflow.outputs.items():
        source = spec.get("source", "")
        cwl["outputs"][name] = {
            "type": spec.get("type", "File"),
            "outputSource": source,
        }

    # Process steps
    for task in workflow.tasks:
        step = {
            "run": f"{task.tool.name}.cwl",
            "in": {},
            "out": list(task.output_aliases.keys()),
        }

        for in_name, source in task.input_bindings.items():
            step["in"][in_name] = source

        cwl["steps"][task.name] = step

    return cwl


def generate_nextflow(workflow: Workflow) -> str:
    """Generate Nextflow DSL2 from workflow definition."""
    tasks_code = []

    for task in workflow.tasks:
        res = task.tool.resources
        tasks_code.append(f'''
process {task.tool.name.upper()} {{
    cpus {res.get("cpu", 1)}
    memory "{res.get("memory", 2048)} MB"
    
    input:
        path reads
    
    output:
        path "*.html", emit: reports
    
    """
    {task.tool.base_command} $reads
    """
}}
''')

    workflow_code = f'''
workflow {{
    reads = Channel.fromFilePairs(params.reads)
    
    {' '.join(f"call {t.tool.name.upper()}" for t in workflow.tasks)}
}}
'''

    return "".join(tasks_code) + workflow_code


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--cwl":
        print(json.dumps(generate_cwl(WORKFLOW), indent=2))
    elif len(sys.argv) > 1 and sys.argv[1] == "--nf":
        print(generate_nextflow(WORKFLOW))
    else:
        print("Usage: python quality_control.py --cwl | --nf")