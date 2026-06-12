#@ BWA MEM alignment with sorting
# in
#   reads [file]
#   reference file
#   reference_fai file
#   sample_name str
# out
#   output_bam file = ${sample_name}.sorted.bam
#   output_bam_index file = ${sample_name}.sorted.bam.bai
#   bwa_log file = ${sample_name}.bwa.log
# run
#   cpu = 4
#   memory = 8192
#   disk = 10240
#   image = quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0

set -e
bwa mem -t ${cpu} -R "@RG\tID:${sample_name}\tLB:1\tPL:ILLUMINA\tSM:${sample_name}" ${reference} ${reads[0]} ${reads[1]} 2> ${sample_name}.bwa.log | samtools sort -@ $((cpu - 1)) -m 2G -o ${sample_name}.sorted.bam - && samtools index ${sample_name}.sorted.bam
