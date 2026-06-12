#@ STAR alignment
# in
#   sample_name str
#   reads [file]
#   reference_index_dir file
#   reference_fasta file
# out
#   alignment file = star_${sample_name}/Aligned.sortedByCoord.out.bam
#   log file = star_${sample_name}/Log.final.out
# run
#   cpu = 8
#   memory = 32768
#   disk = 20480
#   image = quay.io/biocontainers/star:2.7.3a--0

set -e
mkdir -p star_${sample_name}
STAR --runMode alignReads --genomeDir ${reference_index_dir} --readFilesIn ${reads[0]} ${reads[1]} --readFilesCommand zcat --runThreadN ${cpu} --outFileNamePrefix star_${sample_name}/ --outSAMtype BAM SortedByCoordinate --outBAMcompression 1 --outSAMunmapped Within KeepPairs --twopassMode Basic --outSAMattrRGline ID:${sample_name} LB:${sample_name} PL:ILLUMINA SM:${sample_name}
