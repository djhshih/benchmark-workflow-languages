#? BWA MEM for CNV
#
# in  reads        array file | paired-end reads
# in  reference    file        | reference sequence
# in  sample_name  str         | sample name
#
# out alignment    file = ${sample_name}.sam | output alignment
#
# run cpu    = 4
# run memory = 8192
# run disk   = 1024

bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample_name}.sam