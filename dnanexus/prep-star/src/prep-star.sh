#!/bin/bash
# prep-star 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of annotations: '$annotations'"
    echo "Value of genome: '$genome'"
    echo "Value of spike_in: '$spike_in'"
    echo "Value of index_prefix: '$index_prefix'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    annotation_fn = `dx describe "$annotations" --name | cut -d'.' -f1`
    dx download "$annotations" -o "$annotation_fn".gtf.gz
    gunzip "$annotation_fn".gtf.gz

    genome_fn = `dx describe "$genome" --name | cut -d'.' -f1`
    dx download "$genome" -o "$genome_fn".fa.gz
    gunzip "$genome_fn".fa.gz
    ref = "$genome_fn".fa


    if [ -n "$spike_in" ]
    then
        spike_in_fn = `dx describe "$genome" --name | cut -d'.' -f1`
        dx download "$spike_in" -o "$spike_in_fn".fa.gz
        gunzip "$spike_in_fn".fa.gz
        $ref = {$ref},{$spike_in_fn}.fa

    fi

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.


    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    (cd /usr/local/STAR; make)
    /usr/local/STAR --runMode genomeGenerate --genomeFastaFiles ${genome_fn}.fa ${spike_in_fn}.fa --sjdbOverhang 100 \
     --sjdbGTFfile ${$annotation_fn}.gtf --runThreadN 6 --genomeDir ./  \
                                         --outFileNamePrefix ${index_prefix}

    # Attempt to make bamCommentLines.txt, which should be reviewed. NOTE tabs handled by assignment.
    refComment="@CO\tREFID:$(basename ${genome_fn})"
    annotationComment="@CO\tANNID:$(basename ${annotation_fn})"
    spikeInComment="@CO\tSPIKEID:${spike_in_fn}"
    echo -e ${refComment} > ${index_prefix}_bamCommentLines.txt
    echo -e ${annotationComment} >> ${index_prefix}_bamCommentLines.txt
    echo -e ${spikeInComment} >> ${index_prefix}_bamCommentLines.txt

    `ls ${index_prefix}*`
    tar -czf {$index_prefix}_starIndex.tgz ${index_prefix}*

    star_index=$(dx upload {$index_prefix}_starIndex.tgz --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output star_index $star_index --class=file
}
