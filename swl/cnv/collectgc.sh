#? Collect GC
#
# in  reference file | reference sequence
# in  intervals file | target intervals
#
# out gc_file file = gc.txt | GC curve
#
# run cpu    = 1
# run memory = 2048
# run disk   = 1024

gatk CountGC -R ${reference} -L ${intervals} -O gc.txt
