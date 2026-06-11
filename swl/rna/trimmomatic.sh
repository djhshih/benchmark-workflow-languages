#@ Trimmomatic adapter trimming
# in
#   reads [file]
#   adapters file
#   sample_name str
# out
#   reads [file] = trimmed_${sample_name}_*.fastq.gz
#   logs [file] = ${sample_name}_*_log.txt
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar trimmomatic.jar PE ${reads[0]} ${reads[1]} \
    trimmed_${sample_name}_R1.fastq.gz trimmed_${sample_name}_R1_unpaired.fastq.gz \
    trimmed_${sample_name}_R2.fastq.gz trimmed_${sample_name}_R2_unpaired.fastq.gz \
    ILLUMINACLIP:${adapters}:2:30:10 LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:15 MINLEN:36