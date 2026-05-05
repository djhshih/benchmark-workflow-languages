#? Trimmomatic adapter trimming
# in
#   reads array file | paired-end reads
#   adapters file | adapter sequences
#   sample_name str | sample name
# out
#   trimmed_reads array file = trimmed_${sample_name}_*.fastq.gz | trimmed reads
#   logs array file = ${sample_name}_*_log.txt | trimming logs
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar trimmomatic.jar PE ${reads[0]} ${reads[1]} \
    trimmed_${sample_name}_R1.fastq.gz trimmed_${sample_name}_R1_unpaired.fastq.gz \
    trimmed_${sample_name}_R2.fastq.gz trimmed_${sample_name}_R2_unpaired.fastq.gz \
    ILLUMINACLIP:${adapters}:2:30:10 LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:15 MINLEN:36