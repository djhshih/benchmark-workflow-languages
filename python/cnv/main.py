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
SAMTOOLS_DOCKER = "quay.io/biocontainers/samtools:1.9--h10a08f8_12"

TOOLS = {
    "bwa_mem": Tool(
        name="bwa_mem",
        base_command='bwa mem -t {cpu} -R "@RG\\tID:{sample}\\tLB:1\\tPL:ILLUMINA\\tSM:{sample}" {reference} {reads_0} {reads_1} 2> {sample}.bwa.log | samtools sort -@ {cpu_minus_1} -m 2G -o {sample}.sorted.bam - && samtools index {sample}.sorted.bam',
        docker_image=BWA_DOCKER,
        inputs={"sample_name": "string", "reads": "array", "reference": "File", "reference_fai": "File"},
        outputs={"output_bam": "{sample}.sorted.bam", "output_bam_index": "{sample}.sorted.bam.bai", "bwa_log": "{sample}.bwa.log"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=10240),
    ),
    "sort_bam": Tool(
        name="sort_bam",
        base_command='samtools sort -@ {cpu} -m 4G -o {sample}.coordinate_sorted.bam -T {sample}.tmp {bam} && samtools index {sample}.coordinate_sorted.bam',
        docker_image="quay.io/biocontainers/samtools:1.21--h96c455f_1",
        inputs={"input_bam": "File", "sample_name": "string"},
        outputs={"sorted_bam": "{sample}.coordinate_sorted.bam"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=10240),
    ),
    "index_bam": Tool(
        name="index_bam",
        base_command='samtools index {bam}',
        docker_image=SAMTOOLS_DOCKER,
        inputs={"input_bam": "File", "sample_name": "string"},
        outputs={"bam_index": "{sample}.coordinate_sorted.bam.bai"},
        resources=Resource(cpu=1, memory_mb=2048, disk_mb=2048),
    ),
    "collect_allelic_counts": Tool(
        name="collect_allelic_counts",
        base_command='gatk --java-options "-Xmx10G -XX:ParallelGCThreads=1" CollectAllelicCounts -L {sites} -I {bam} -R {ref} -O {sample}.allelic_counts.tsv',
        docker_image=GATK_DOCKER,
        inputs={"input_bam": "File", "sample_name": "string", "reference": "File", "reference_dict": "File", "reference_fai": "File", "sites": "File", "sites_index": "File"},
        outputs={"allelic_counts": "{sample}.allelic_counts.tsv"},
        resources=Resource(cpu=2, memory_mb=10240, disk_mb=5120),
    ),
    "collect_read_counts": Tool(
        name="collect_read_counts",
        base_command='gatk --java-options "-Xmx7G -XX:ParallelGCThreads=1" CollectReadCounts -L {intervals} -I {bam} -R {ref} --format HDF5 --interval-merging-rule OVERLAPPING_ONLY -O {sample}.read_counts.hdf5',
        docker_image=GATK_DOCKER,
        inputs={"input_bam": "File", "sample_name": "string", "reference": "File", "reference_dict": "File", "reference_fai": "File", "intervals": "File"},
        outputs={"read_counts": "{sample}.read_counts.hdf5"},
        resources=Resource(cpu=2, memory_mb=7168, disk_mb=5120),
    ),
    "denoise_read_counts": Tool(
        name="denoise_read_counts",
        base_command='gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" DenoiseReadCounts -I {counts} {pon_args} --standardized-copy-ratios {sample}.standardizedCR.tsv --denoised-copy-ratios {sample}.denoisedCR.tsv',
        docker_image=GATK_DOCKER,
        inputs={"read_counts": "File", "sample_name": "string", "pon": "File"},
        outputs={"denoised_cr": "{sample}.denoisedCR.tsv", "standardized_cr": "{sample}.standardizedCR.tsv"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=2048),
    ),
    "model_segments": Tool(
        name="model_segments",
        base_command='gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" ModelSegments --denoised-copy-ratios {cr} --allelic-counts {ac} --output-prefix {sample}. -O .',
        docker_image=GATK_DOCKER,
        inputs={"denoised_cr": "File", "standardized_cr": "File", "allelic_counts": "File", "sample_name": "string"},
        outputs={"modeled": "{sample}.modelFinal.seg", "copy_ratio": "{sample}.cr.seg", "allelic_seg": "{sample}.af.seg"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=5120),
    ),
    "call_copy_ratio_segments": Tool(
        name="call_copy_ratio_segments",
        base_command='gatk --java-options "-Xmx2G -XX:ParallelGCThreads=1" CallCopyRatioSegments -I {segments} -O {sample}.called.seg',
        docker_image=GATK_DOCKER,
        inputs={"segments": "File", "sample_name": "string"},
        outputs={"called_segments": "{sample}.called.seg"},
        resources=Resource(cpu=1, memory_mb=2048, disk_mb=2048),
    ),
}

CNV_PIPELINE = Pipeline(
    name="cnv_calling",
    inputs={
        "sample_name": "string",
        "reads": "array",
        "reference": "File",
        "reference_dict": "File",
        "reference_fai": "File",
        "common_variant_sites": "File",
        "common_variant_sites_index": "File",
        "intervals": "File",
        "pon": "File",
    },
    tools=TOOLS,
    steps=[
        Step(id="align", tool="bwa_mem", inputs={"sample_name": "inputs.sample_name", "reads": "inputs.reads", "reference": "inputs.reference", "reference_fai": "inputs.reference_fai"}),
        Step(id="sort", tool="sort_bam", inputs={"input_bam": "align.output_bam", "sample_name": "inputs.sample_name"}),
        Step(id="index", tool="index_bam", inputs={"input_bam": "sort.sorted_bam", "sample_name": "inputs.sample_name"}),
        Step(id="allelic_counts", tool="collect_allelic_counts", inputs={"input_bam": "sort.sorted_bam", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_dict": "inputs.reference_dict", "reference_fai": "inputs.reference_fai", "sites": "inputs.common_variant_sites", "sites_index": "inputs.common_variant_sites_index"}),
        Step(id="read_counts", tool="collect_read_counts", inputs={"input_bam": "sort.sorted_bam", "sample_name": "inputs.sample_name", "reference": "inputs.reference", "reference_dict": "inputs.reference_dict", "reference_fai": "inputs.reference_fai", "intervals": "inputs.intervals"}),
        Step(id="denoise", tool="denoise_read_counts", inputs={"read_counts": "read_counts.read_counts", "sample_name": "inputs.sample_name", "pon": "inputs.pon"}),
        Step(id="model", tool="model_segments", inputs={"denoised_cr": "denoise.denoised_cr", "standardized_cr": "denoise.standardized_cr", "allelic_counts": "allelic_counts.allelic_counts", "sample_name": "inputs.sample_name"}),
        Step(id="call", tool="call_copy_ratio_segments", inputs={"segments": "model.copy_ratio", "sample_name": "inputs.sample_name"}),
    ],
    outputs={
        "called_segments": "call.called_segments",
    },
)

if __name__ == "__main__":
    print("CNV Pipeline defined with", len(CNV_PIPELINE.steps), "steps")
