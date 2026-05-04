#? featureCounts quantification
# in  alignment  file | aligned BAM
# in  annotation  file | GTF annotation
# out counts     file = counts.txt | read counts
# out summary    file = counts.txt.summary | count summary
# run cpu    = 4
# run memory = 8192
# run disk   = 1024

featureCounts -T ${cpu} -a ${annotation} -o counts.txt ${alignment}