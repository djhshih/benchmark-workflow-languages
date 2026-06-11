#@ Base Recalibrator
# in
#   input file
#   reference file
#   known_sites [file]
# out
#   recal_table file = recal.table
#   report file = report.txt
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar gatk BaseRecalibrator -I ${input} -R ${reference} --known-sites ${known_sites[0]} --known-sites ${known_sites[1]} -O recal.table -BQSR report.txt