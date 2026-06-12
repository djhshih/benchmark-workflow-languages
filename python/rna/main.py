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
    "trimmomatic": Tool(
        name="trimmomatic",
        base_command='trimmomatic PE -threads {cpu} {reads_0} {reads_1} {sample}_R1.trimmed.fastq.gz {sample}_R1.unpaired.fastq.gz {sample}_R2.trimmed.fastq.gz {sample}_R2.unpaired.fastq.gz ILLUMINACLIP:{adapters}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36',
        docker_image="quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7",
        inputs={"sample_name": "string", "reads": "array", "adapters": "File"},
        outputs={"trimmed_r1": "{sample}_R1.trimmed.fastq.gz", "trimmed_r2": "{sample}_R2.trimmed.fastq.gz", "unpaired_r1": "{sample}_R1.unpaired.fastq.gz", "unpaired_r2": "{sample}_R2.unpaired.fastq.gz"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=5120),
    ),
    "star": Tool(
        name="star",
        base_command='STAR --runMode alignReads --runThreadN {cpu} --genomeDir {index_dir} --readFilesIn {reads_0} {reads_1} --readFilesCommand zcat --outFileNamePrefix star_{sample}/ --outSAMtype BAM SortedByCoordinate --outBAMcompression 1 --outSAMunmapped Within KeepPairs --twopassMode Basic --outSAMattrRGline ID:{sample} LB:{sample} PL:ILLUMINA SM:{sample}',
        docker_image="quay.io/biocontainers/star:2.7.3a--0",
        inputs={"sample_name": "string", "reads": "array", "reference_index": "Directory", "reference_fasta": "File"},
        outputs={"alignment_bam": "star_{sample}/Aligned.sortedByCoord.out.bam", "alignment_log": "star_{sample}/Log.final.out", "sj_tab": "star_{sample}/SJ.out.tab"},
        resources=Resource(cpu=8, memory_mb=32768, disk_mb=20480),
    ),
    "fastqc": Tool(
        name="fastqc",
        base_command='fastqc --outdir fastqc_{sample} --threads {cpu} {trimmed_r1} {trimmed_r2}',
        docker_image="quay.io/biocontainers/fastqc:0.11.9--0",
        inputs={"sample_name": "string", "trimmed_r1": "File", "trimmed_r2": "File"},
        outputs={"html_report_r1": "fastqc_{sample}/{sample}_R1.trimmed_fastqc.html", "html_report_r2": "fastqc_{sample}/{sample}_R2.trimmed_fastqc.html", "zip_report_r1": "fastqc_{sample}/{sample}_R1.trimmed_fastqc.zip", "zip_report_r2": "fastqc_{sample}/{sample}_R2.trimmed_fastqc.zip"},
        resources=Resource(cpu=2, memory_mb=4096, disk_mb=2048),
    ),
    "featurecounts": Tool(
        name="featurecounts",
        base_command='featureCounts -T {cpu} -a {annotation} -s {strand_flag} -o {sample}_counts.txt {alignment}',
        docker_image="quay.io/biocontainers/subread:2.0.1--hed695b0_0",
        inputs={"sample_name": "string", "alignment": "File", "annotation": "File", "strand_flag": "string"},
        outputs={"counts": "{sample}_counts.txt", "counts_summary": "{sample}_counts.txt.summary"},
        resources=Resource(cpu=4, memory_mb=8192, disk_mb=5120),
    ),
}

RNA_PIPELINE = Pipeline(
    name="rna_seq",
    inputs={
        "sample_name": "string",
        "reads": "array",
        "adapters": "File",
        "reference_index": "Directory",
        "reference_fasta": "File",
        "annotation": "File",
        "strand_flag": "string",
    },
    tools=TOOLS,
    steps=[
        Step(id="trim", tool="trimmomatic", inputs={"sample_name": "inputs.sample_name", "reads": "inputs.reads", "adapters": "inputs.adapters"}),
        Step(id="align", tool="star", inputs={"sample_name": "inputs.sample_name", "reads": "inputs.reads", "reference_index": "inputs.reference_index", "reference_fasta": "inputs.reference_fasta"}),
        Step(id="qc", tool="fastqc", inputs={"sample_name": "inputs.sample_name", "trimmed_r1": "trim.trimmed_r1", "trimmed_r2": "trim.trimmed_r2"}),
        Step(id="counts", tool="featurecounts", inputs={"sample_name": "inputs.sample_name", "alignment": "align.alignment_bam", "annotation": "inputs.annotation", "strand_flag": "inputs.strand_flag"}),
    ],
    outputs={
        "counts": "counts.counts",
        "qc_report_r1": "qc.html_report_r1",
        "qc_report_r2": "qc.html_report_r2",
    },
)

if __name__ == "__main__":
    print("RNA-seq Pipeline defined with", len(RNA_PIPELINE.steps), "steps")
