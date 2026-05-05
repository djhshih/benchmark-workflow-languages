#? Apply BQSR
# in
#   bam file | input BAM
#   recal_table file | recalibration table
#   reference file | reference genome
#   sample_name str | sample name
# out
#   bam file = ${sample_name}_recalibrated.bam | recalibrated BAM
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar gatk ApplyBQSR -I ${bam} -R ${reference} --bqsr-recal-file ${recal_table} -O ${sample_name}_recalibrated.bam