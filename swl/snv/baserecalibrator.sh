#? Base Recalibrator
#
# in  input       file        | input bam
# in  reference   file        | reference sequence
# in  known_sites array file  | known variant sites
#
# out recal_table file = recal.table | recal table
# out report     file = report.txt   | report
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

java -jar gatk BaseRecalibrator -I ${input} -R ${reference} --known-sites ${known_sites[0]} -O recal.table -BQSR report.txt