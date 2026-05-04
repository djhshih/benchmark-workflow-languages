cwlVersion: v1.0
class: Workflow

inputs:
  sample_name: string
  reads:
    type: array
    items: File
  reference: File
  target_regions: File
  reference_panel:
    type: array
    items: File

outputs:
  cnv_calls:
    type: File
    outputSource: call_cnv/cnv_calls
  coverage:
    type: File
    outputSource: collect_coverage/counts

steps:
  align:
    run: bwa-mem.cwl
    in:
      reads: reads
      reference: reference
    out: [alignment]

  sort:
    run: sort-bam.cwl
    in:
      alignment: align/alignment
    out: [sorted_bam]

  index:
    run: index-bam.cwl
    in:
      bam: sort/sorted_bam
    out: [indexed_bam]

  collect_coverage:
    run: collectreadcounts.cwl
    in:
      bam: index/indexed_bam
      reference: reference
      intervals: target_regions
    out: [counts]

  collect_gc:
    run: collectgc.cwl
    in:
      reference: reference
      intervals: target_regions
    out: [gc_file]

  denoise:
    run: denoisecoverage.cwl
    in:
      counts: collect_coverage/counts
      gc_file: collect_gc/gc_file
      reference_panel: reference_panel
    out: [denoised_cr]

  segment:
    run: segmentcnv.cwl
    in:
      denoised_cr: denoise/denoised_cr
      intervals: target_regions
    out: [segments]

  call_cnv:
    run: callcnv.cwl
    in:
      segments: segment/segments
      sample_name: sample_name
    out: [cnv_calls]

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement