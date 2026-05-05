#? STAR alignment
# in
#   reads array file | paired-end reads
#   reference_index dir | STAR index directory
# out
#   alignment file = *.bam | aligned BAM
#   log file = *.log | alignment log
# run
#   cpu = 8
#   memory = 32768
#   disk = 10240

STAR --runMode alignReads --runThreadN ${cpu} \
    --genomeDir ${reference_index} --readFilesIn ${reads[0]} ${reads[1]} \
    --outFileNamePrefix ./
