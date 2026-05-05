#? STAR alignment
# in
#   reads array file | paired-end reads
#   reference_index dir | STAR index directory
#   sample_name str | sample name
# out
#   alignment file = ${sample_name}_Aligned.sorted.bam | aligned BAM
#   log file = ${sample_name}*.log | alignment log
# run
#   cpu = 8
#   memory = 32768
#   disk = 10240

STAR --runMode alignReads --runThreadN ${cpu} \
    --genomeDir ${reference_index} --readFilesIn ${reads[0]} ${reads[1]} \
    --outFileNamePrefix ${sample_name}_