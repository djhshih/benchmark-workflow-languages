#!/usr/bin/env python3
"""
Declarative bioinformatics pipeline in Python.

This uses a minimal DSL approach - define tasks and workflows in a declarative
style, then generate CWL or other targets.
"""

# Define tasks in a declarative way
TASKS = {
    "fastqc": {
        "base_command": "fastqc",
        "inputs": {"reads": "array"},
        "outputs": {"reports": "*.html"},
        "resources": {"cpu": 1, "memory_mb": 2048},
    },
    "trimmomatic": {
        "base_command": "java -jar trimmomatic.jar PE",
        "inputs": {"reads": "array", "adapters": "File"},
        "outputs": {
            "trimmed_reads": "*.fastq.gz",
            "step_log": "*_log.txt",
        },
        "resources": {"cpu": 2, "memory_mb": 4096},
    },
    "bowtie2": {
        "base_command": "bowtie2",
        "inputs": {"reads": "array", "reference_index": "File"},
        "outputs": {"sorted_bam": "*.bam"},
        "resources": {"cpu": 4, "memory_mb": 8192},
    },
}

# Define workflow
WORKFLOW = {
    "name": "quality-control",
    "inputs": {
        "reads": "File",
        "adapters": "File",
        "reference_index": "File",
    },
    "outputs": {
        "trimmed_reports": "trim.step_log",
        "alignment": "align.sorted_bam",
        "qc_reports": "post_qc.reports",
    },
    "steps": [
        {"id": "initial_qc", "task": "fastqc", "inputs": {"reads": "reads"}},
        {"id": "trim", "task": "trimmomatic", "inputs": {"reads": "reads", "adapters": "adapters"}},
        {"id": "post_qc", "task": "fastqc", "inputs": {"reads": "trim.trimmed_reads"}},
        {"id": "align", "task": "bowtie2", "inputs": {"reads": "trim.trimmed_reads", "reference_index": "reference_index"}},
    ],
}


def to_cwl():
    """Generate CWL from declarative pipeline."""
    # This would be a proper transpiler in real implementation
    return {
        "cwlVersion": "v1.0",
        "class": "Workflow",
        "inputs": [
            {"id": k, "type": v} for k, v in WORKFLOW["inputs"].items()
        ],
        "steps": [
            {
                "id": s["id"],
                "run": f"{s['task']}.cwl",
                "in": s["inputs"],
            }
            for s in WORKFLOW["steps"]
        ],
    }


def to_nextflow():
    """Generate Nextflow from declarative pipeline."""
    # This would be a proper transpiler in real implementation
    nf_code = []
    for task_id, task_def in TASKS.items():
        res = task_def["resources"]
        nf_code.append(f'''
process {task_id.upper()} {{
    cpus {res["cpu"]}
    memory "{res["memory_mb"]} MB"
    
    input: path reads
    output: path "*.html"
    
    command: "{task_def['base_command']} $reads"
}}
''')
    return "\n".join(nf_code)


if __name__ == "__main__":
    import json
    print(json.dumps(to_cwl(), indent=2))