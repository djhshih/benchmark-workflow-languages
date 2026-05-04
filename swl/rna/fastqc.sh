#? FastQC quality control
# in  reads    array file | input reads
# out reports  array file = *.html | QC reports
# run cpu    = 2
# run memory = 4096
# run disk   = 512

fastqc --outdir . ${reads[0]} ${reads[1]}