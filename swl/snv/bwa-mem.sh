#? BWA MEM alignment
# in
#   reads array file | paired-end reads
#   reference file | reference sequence
#   sample_name str | sample name
# out
#   alignment file = ${sample_name}.sam | output alignment
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample_name}.sam