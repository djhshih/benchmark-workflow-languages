#@ STAR alignment
# in
#   reads [file]
#   reference_index file
#   sample_name str
# out
#   alignment file = ${sample_name}_Aligned.sorted.bam
#   log file = ${sample_name}*.log
# run
#   cpu = 8
#   memory = 32768
#   disk = 10240

STAR --runMode alignReads --runThreadN ${cpu} \
    --genomeDir ${reference_index} --readFilesIn ${reads[0]} ${reads[1]} \
    --outFileNamePrefix ${sample_name}_