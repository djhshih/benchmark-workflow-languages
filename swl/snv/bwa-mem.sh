#@ BWA MEM alignment
# in
#   reads [file]
#   reference file 
#   sample_name str
# out
#   alignment file = ${sample_name}.sam
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample_name}.sam
