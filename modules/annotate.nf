process ANNOTATE {
    tag "${cohort}.${version}"

    label 'simple'
    label 'bcftools'

    publishDir("${params.output_dir}/annotated/", mode: 'copy')

    input:
    tuple val(version), path(anno_file), path(anno_index),
          val(cohort), path(vcf), path(vcf_index)

    output:
    tuple val(cohort), val(version),
          path("${cohort}.${version}.vcf.gz"),
          path("${cohort}.${version}.vcf.gz.tbi")

    script:
    """
    #!/bin/bash
    # Rename and annotate
    bcftools annotate -a ${anno_file} -c INFO -h <(bcftools view -h ${anno_file} | grep CSQ) ${vcf} | \
    bcftools view --threads ${task.cpus} -Oz -o ${cohort}.${version}.vcf.gz
    tabix ${cohort}.${version}.vcf.gz
    """
}
