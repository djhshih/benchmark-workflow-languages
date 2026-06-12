#@ featureCounts quantification
# in
#   sample_name str
#   alignment file
#   annotation file
#   strandedness str = "NONE"
# out
#   counts file = ${sample_name}_counts.txt
#   summary file = ${sample_name}_counts.txt.summary
# run
#   cpu = 4
#   memory = 8192
#   disk = 5120
#   image = quay.io/biocontainers/subread:2.0.1--hed695b0_0

set -e
if [ "${strandedness}" = "YES" ]; then strand_flag=1; elif [ "${strandedness}" = "REVERSE" ]; then strand_flag=2; else strand_flag=0; fi
featureCounts -T ${cpu} -a ${annotation} -s ${strand_flag} -o ${sample_name}_counts.txt ${alignment}
