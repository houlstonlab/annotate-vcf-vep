process COMBINE {
    tag "${cohort}"

    label 'simple'
    label 'bcftools'

    publishDir("${params.output_dir}/combined", mode: 'copy')

    input:
    tuple val(cohort), val(sample),
          val(file), path(index)

    output:
    tuple val(cohort), val(sample),
          path("${cohort}.vcf.gz"),
          path("${cohort}.vcf.gz.tbi"),
          path("${cohort}.cases.txt"),
          path("${cohort}.variants.tsv")

    script:
    """
    #!/bin/bash
    # Merge
    bcftools concat --naive -f <(echo "${file.join('\n')}" | uniq) | \
    bcftools view -g het --threads ${task.cpus} -Oz -o ${cohort}.vcf.gz

    # Index
    tabix ${cohort}.vcf.gz

    # Extract cases
    bcftools query -l ${cohort}.vcf.gz > ${cohort}.cases.txt

    # Extract variants
	bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%ID\t%TYPE\n' ${cohort}.vcf.gz > ${cohort}.variants.tsv
    """
}

// ( params.by == 'sample' ? bcftools merge -l <(echo "${file.join('\n')}" | uniq) : bcftools concat --naive -f <(echo "${file.join('\n')}" | uniq) ) | \
// bcftools merge -l <(echo "${file.join('\n')}" | uniq) | \
