#@ BWA MEM for CNV
# in
#   reads [file]
#   reference file
#   sample_name str
# out
#   sam file = ${sample_name}.sam
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample_name}.sam