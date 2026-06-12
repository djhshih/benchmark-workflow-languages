#@ Trimmomatic adapter trimming
# in
#   sample_name str
#   reads [file]
#   adapters file
# out
#   trimmed_reads [file] = ${sample_name}_*.trimmed.fastq.gz
# run
#   cpu = 2
#   memory = 4096
#   disk = 5120
#   image = quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7

set -e
trimmomatic PE -threads ${cpu} ${reads[0]} ${reads[1]} ${sample_name}_R1.trimmed.fastq.gz ${sample_name}_R1.unpaired.fastq.gz ${sample_name}_R2.trimmed.fastq.gz ${sample_name}_R2.unpaired.fastq.gz ILLUMINACLIP:${adapters}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
