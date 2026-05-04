#? Apply BQSR
#
# in  input       file | input bam
# in  recal_table file | recalibration table
# in  reference   file | reference sequence
#
# out recalibrated_bam file = recalibrated.bam | output bam
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

java -jar gatk ApplyBQSR -I ${input} -R ${reference} --bqsr-recal-file ${recal_table} -O recalibrated.bam