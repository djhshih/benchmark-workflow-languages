#@ Collect GC
# in
#   reference file
#   intervals file
# out
#   gc_file file = gc.txt
# run
#   cpu = 1
#   memory = 2048
#   disk = 1024

gatk CountGC -R ${reference} -L ${intervals} -O gc.txt
