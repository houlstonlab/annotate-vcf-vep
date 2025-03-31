#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include modules
include { EXTRACT }     from './modules/extract.nf'
include { CONVERT }     from './modules/convert.nf'
include { VEP }         from './modules/vep.nf'
include { CONCATINATE } from './modules/concatinate.nf'
include { ANNOTATE }    from './modules/annotate.nf'

process SORT_UNIQ {
    publishDir("${params.output_dir}/variants", mode: 'copy')

    input:
    path variants_file

    output:
    path "${variants_file.simpleName}.unique.txt"

    script:
    """
    cat ${variants_file} | sort -Vu > ${variants_file.simpleName}.unique.txt
    """
}

// Subworkflow
workflow ANNOTATE_VCF_VEP {
    take:
    cohort_info_ch

    main:
    cohort_info_ch
        | EXTRACT
        | map { it.last() }
        | collectFile(
            storeDir : "${params.output_dir}/variants",
            name     : 'variants.txt'
        )
        | SORT_UNIQ
        | splitText(
            by   : params.chunk.toInteger(),
            limit: params.limit.toInteger(),
            file : 'chunk',
            elem : 1
        )
        | map { [it.fileName, it] }
        | CONVERT
        | VEP
        | groupTuple(by: 0)
        | CONCATINATE
        | combine(cohort_info_ch)
        | ANNOTATE
    emit:
    ANNOTATE.out
}

// Workflow
workflow {
    // Define input from file
    cohort_info_ch = Channel.fromPath(params.cohort_info)
        | splitCsv(header: true, sep: ',')
        | map { row -> [ row.cohort, file(row.file), file(row.index) ]}

    ANNOTATE_VCF_VEP(cohort_info_ch)
}
