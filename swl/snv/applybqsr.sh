#? Apply BQSR
# in
#   input file | input BAM
#   recal_table file | recalibration table
#   reference file | reference genome
# out
#   recalibrated_bam file = recalibrated.bam | recalibrated BAM
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar gatk ApplyBQSR -I ${input} -R ${reference} --bqsr-recal-file ${recal_table} -O recalibrated.bam