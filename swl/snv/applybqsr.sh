#@ Apply BQSR
# in
#   bam file
#   recal_table file
#   reference file
#   sample_name str
# out
#   bam file = ${sample_name}_recalibrated.bam
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar gatk ApplyBQSR -I ${bam} -R ${reference} --bqsr-recal-file ${recal_table} -O ${sample_name}_recalibrated.bam