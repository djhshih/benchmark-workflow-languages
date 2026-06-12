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

TOOLS = {
    "minimap2_map": Tool(
        name="minimap2_map",
        base_command='minimap2 -a -x {preset} -t {cpu} -y -R "@RG\\tID:{sample}\\tSM:{sample}\\tPL:{platform}" {ref_fasta} {reads} | samtools sort --threads 2 -m 1G -o {sample}.sorted.bam - && samtools index {sample}.sorted.bam',
        docker_image="quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0",
        inputs={"sample_name": "string", "reads": "File", "reference_fasta": "File", "preset": "string", "platform": "string"},
        outputs={"sorted_bam": "{sample}.sorted.bam", "sorted_bam_index": "{sample}.sorted.bam.bai"},
        resources=Resource(cpu=8, memory_mb=24576, disk_mb=10240),
    ),
    "mosdepth_cov": Tool(
        name="mosdepth_cov",
        base_command='mosdepth --threads {cpu} --no-per-base {sample}.mosdepth {bam}',
        docker_image="quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1",
        inputs={"bam": "File", "sample_name": "string"},
        outputs={"mosdepth_global": "{sample}.mosdepth.mosdepth.global.dist.txt", "mosdepth_per_region": "{sample}.mosdepth.mosdepth.region.dist.txt", "mosdepth_summary": "{sample}.mosdepth.mosdepth.summary.txt"},
        resources=Resource(cpu=4, memory_mb=4096, disk_mb=2048),
    ),
    "clair3_call": Tool(
        name="clair3_call",
        base_command='run_clair3.sh --model={model} --ref_fn={ref_fasta} --bam_fn={bam} --output=clair3_out --threads={cpu} --platform={platform} --sample_name={sample} && mv clair3_out/merge_output.vcf.gz {sample}.clair3.vcf.gz && mv clair3_out/merge_output.vcf.gz.tbi {sample}.clair3.vcf.gz.tbi && rm -rf clair3_out',
        docker_image="quay.io/biocontainers/clair3:1.1.0--py39hd649744_0",
        inputs={"bam": "File", "ref_fasta": "File", "reference_fasta_fai": "File", "model": "string", "platform": "string", "sample_name": "string"},
        outputs={"clair3_vcf": "{sample}.clair3.vcf.gz", "clair3_vcf_index": "{sample}.clair3.vcf.gz.tbi"},
        resources=Resource(cpu=8, memory_mb=24576, disk_mb=20480),
    ),
    "bcftools_stats": Tool(
        name="bcftools_stats",
        base_command='bcftools stats {vcf} > {sample}.vcf.stats',
        docker_image="quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2",
        inputs={"input_vcf": "File", "sample_name": "string"},
        outputs={"vcf_stats": "{sample}.vcf.stats"},
        resources=Resource(cpu=1, memory_mb=256, disk_mb=512),
    ),
    "multiqc_report": Tool(
        name="multiqc_report",
        base_command='multiqc --force --outdir {sample}_multiqc {reports}',
        docker_image="quay.io/biocontainers/multiqc:1.28--pyhdfd78af_0",
        inputs={"reports": "string", "sample_name": "string"},
        outputs={"multiqc_report": "{sample}_multiqc/multiqc_report.html"},
        resources=Resource(cpu=1, memory_mb=2048, disk_mb=512),
    ),
}

LONG_READ_PIPELINE = Pipeline(
    name="long_read_calling",
    inputs={
        "sample_name": "string",
        "reads": "File",
        "reference_fasta": "File",
        "reference_fasta_fai": "File",
        "preset": "string",
        "platform": "string",
        "model": "string",
    },
    tools=TOOLS,
    steps=[
        Step(id="align", tool="minimap2_map", inputs={"sample_name": "inputs.sample_name", "reads": "inputs.reads", "reference_fasta": "inputs.reference_fasta", "preset": "inputs.preset", "platform": "inputs.platform"}),
        Step(id="coverage", tool="mosdepth_cov", inputs={"bam": "align.sorted_bam", "sample_name": "inputs.sample_name"}),
        Step(id="variant_call", tool="clair3_call", inputs={"bam": "align.sorted_bam", "ref_fasta": "inputs.reference_fasta", "reference_fasta_fai": "inputs.reference_fasta_fai", "model": "inputs.model", "platform": "inputs.platform", "sample_name": "inputs.sample_name"}),
        Step(id="stats", tool="bcftools_stats", inputs={"input_vcf": "variant_call.clair3_vcf", "sample_name": "inputs.sample_name"}),
        Step(id="report", tool="multiqc_report", inputs={"reports": "coverage.mosdepth_summary stats.vcf_stats", "sample_name": "inputs.sample_name"}),
    ],
    outputs={
        "sorted_bam": "align.sorted_bam",
        "clair3_vcf": "variant_call.clair3_vcf",
        "vcf_stats": "stats.vcf_stats",
        "multiqc_report": "report.multiqc_report",
    },
)

if __name__ == "__main__":
    print("Long-read Pipeline defined with", len(LONG_READ_PIPELINE.steps), "steps")
