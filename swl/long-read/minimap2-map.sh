#@ Minimap2 long read alignment with sorting
# in
#   sample_name str
#   reads file
#   reference_fasta file
#   preset str = "map-ont"
#   platform str = "ont"
# out
#   output_bam file = ${sample_name}.sorted.bam
#   output_bam_index file = ${sample_name}.sorted.bam.bai
# run
#   cpu = 8
#   memory = 24576
#   disk = 10240
#   image = quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0

set -e
minimap2 -a -x ${preset} -t ${cpu} -y -R "@RG\tID:${sample_name}\tSM:${sample_name}\tPL:${platform}" ${reference_fasta} ${reads} | samtools sort --threads 2 -m 1G -o ${sample_name}.sorted.bam - && samtools index ${sample_name}.sorted.bam
