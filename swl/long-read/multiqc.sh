#@ MultiQC report aggregation
# in
#   sample_name str
#   reports [file]
# out
#   report file = ${sample_name}_multiqc/multiqc_report.html
# run
#   cpu = 1
#   memory = 2048
#   disk = 512
#   image = quay.io/biocontainers/multiqc:1.28--pyhdfd78af_0

set -e
multiqc --force --outdir ${sample_name}_multiqc ${reports[@]}
