#? featureCounts quantification
# in
#   alignment file | aligned BAM
#   annotation file | GTF annotation
#   sample_name str | sample name
# out
#   counts file = ${sample_name}_counts.txt | read counts
#   summary file = ${sample_name}_counts.txt.summary | count summary
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

featureCounts -T ${cpu} -a ${annotation} -o ${sample_name}_counts.txt ${alignment}