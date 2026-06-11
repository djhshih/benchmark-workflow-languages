#@ featureCounts quantification
# in
#   alignment file
#   annotation file
#   sample_name str
# out
#   counts file = ${sample_name}_counts.txt
#   summary file = ${sample_name}_counts.txt.summary
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

featureCounts -T ${cpu} -a ${annotation} -o ${sample_name}_counts.txt ${alignment}