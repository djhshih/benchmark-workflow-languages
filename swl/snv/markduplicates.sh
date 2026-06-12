#@ Mark Duplicates
# in
#   input_bam file
#   input_bam_index file
#   sample_name str
# out
#   deduped_bam file = ${sample_name}.deduped.bam
#   deduped_bam_index file = ${sample_name}.deduped.bai
#   metrics file = ${sample_name}.deduped.metrics.txt
# run
#   cpu = 2
#   memory = 7168
#   disk = 10240
#   image = quay.io/biocontainers/picard:3.3.0--hdfd78af_0

picard MarkDuplicates INPUT=${input_bam} OUTPUT=${sample_name}.deduped.bam METRICS_FILE=${sample_name}.deduped.metrics.txt CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CLEAR_DT=false
