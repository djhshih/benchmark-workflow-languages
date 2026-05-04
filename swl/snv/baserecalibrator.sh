#? Base Recalibrator
# in
#   input file | input BAM
#   reference file | reference genome
#   known_sites array | known variant sites
# out
#   recal_table file = recal.table | recalibration table
#   report file = report.txt | recalibration report
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar gatk BaseRecalibrator -I ${input} -R ${reference} --known-sites ${known_sites[0]} --known-sites ${known_sites[1]} -O recal.table -BQSR report.txt