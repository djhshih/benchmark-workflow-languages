#? featureCounts quantification
# in
#   alignment file | aligned BAM
#   annotation file | GTF annotation
# out
#   counts file = counts.txt | read counts
#   summary file = counts.txt.summary | count summary
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

featureCounts -T ${cpu} -a ${annotation} -o counts.txt ${alignment}