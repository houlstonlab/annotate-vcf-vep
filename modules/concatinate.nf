process CONCATINATE {
    tag "${version}"

    label 'simple'
    label 'bcftools'


    publishDir("${params.output_dir}/concatinated/", mode: 'copy')

    input:
    tuple val(version), val(id), path(file), path(index)

    output:
    tuple val(version), 
          path("${version}.annotations.vcf.gz"),
          path("${version}.annotations.vcf.gz.tbi")
        
    script:
    """
    #!/bin/bash
    # Combine vcfs
    bcftools concat \
        -f <(echo "${file.join('\n')}" | sort -V) \
        --naive \
        --threads ${task.cpus} \
        -Oz -o ${version}.annotations.vcf.gz

    tabix ${version}.annotations.vcf.gz
    """
}
