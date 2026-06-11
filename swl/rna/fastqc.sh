#@ FastQC quality control
# in
#   reads [file]
#   sample_name str
# out
#   reports [file] = ${sample_name}_*.html
# run
#   cpu = 2
#   memory = 4096
#   disk = 512

fastqc --outdir . ${reads[0]} ${reads[1]}