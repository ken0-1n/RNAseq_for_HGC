#! /bin/bash
#$ -S /bin/bash
#$ -cwd
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

readonly OUTPUTDIR=$1
readonly TAG=$2

source ${RNA_ENV}
source ${UTIL}

check_num_args $# 2

readonly INPUTPATH=${OUTPUTDIR}/sequence
readonly OUTPUTDIR=${OUTPUTDIR}/fusion
readonly CUFFPATH=${OUTPUTDIR}/cufflink


if [ -f ${CUFFPATH}/transcripts.gtf ]; then
  # convert .gtf fiile to .bed file
  echo "perl ${COMMAND_FUSION}/gtf2bed.pl ${CUFFPATH}/transcripts.gtf > ${OUTPUTDIR}/transcripts.cuff.bed"
  perl ${COMMAND_FUSION}/gtf2bed.pl ${CUFFPATH}/transcripts.gtf > ${OUTPUTDIR}/transcripts.cuff.bed
  check_error $?

  # extract sequence data from the above .bed file
  echo "${BEDTOOLS_PATH}/fastaFromBed -fi ${REF_FA} -bed ${OUTPUTDIR}/transcripts.cuff.bed -fo ${OUTPUTDIR}/transcripts.cuff.tmp.fasta -tab -name -s"
  ${BEDTOOLS_PATH}/fastaFromBed -fi ${REF_FA} -bed ${OUTPUTDIR}/transcripts.cuff.bed -fo ${OUTPUTDIR}/transcripts.cuff.tmp.fasta -tab -name -s
  check_error $?

  # concatinate the .fasta records whose sequences are the same
  echo "perl ${COMMAND_FUSION}/catSeq.pl ${OUTPUTDIR}/transcripts.cuff.tmp.fasta > ${OUTPUTDIR}/transcripts.cuff.fasta"
  perl ${COMMAND_FUSION}/catSeq.pl ${OUTPUTDIR}/transcripts.cuff.tmp.fasta > ${OUTPUTDIR}/transcripts.cuff.fasta
  check_error $?

  # gather the .fasta file for annotated genes and .fasta file for newly assembled transcriptome
  echo "cat ${ALLGENEREF} ${OUTPUTDIR}/transcripts.cuff.fasta > ${OUTPUTDIR}/transcripts.allGene_cuff.fasta"
  cat ${ALLGENEREF} ${OUTPUTDIR}/transcripts.cuff.fasta > ${OUTPUTDIR}/transcripts.allGene_cuff.fasta
  check_error $?

else
  echo "cp ${ALLGENEREF} ${OUTPUTDIR}/transcripts.allGene_cuff.fasta"
  cp ${ALLGENEREF} ${OUTPUTDIR}/transcripts.allGene_cuff.fasta
  check_error $?

fi

# mapping the contigs to the .fasta file
echo "${BLAT_PATH}/blat -maxIntron=5 ${OUTPUTDIR}/transcripts.allGene_cuff.fasta ${OUTPUTDIR}/juncContig.fa ${OUTPUTDIR}/juncContig_allGene_cuff.psl"
${BLAT_PATH}/blat -maxIntron=5 ${OUTPUTDIR}/transcripts.allGene_cuff.fasta ${OUTPUTDIR}/juncContig.fa ${OUTPUTDIR}/juncContig_allGene_cuff.psl
check_error $?


echo "perl ${COMMAND_FUSION}/psl2bed_junc.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl > ${OUTPUTDIR}/juncContig_allGene_cuff.bed"
perl ${COMMAND_FUSION}/psl2bed_junc.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl > ${OUTPUTDIR}/juncContig_allGene_cuff.bed
check_error $?

if [ -f ${OUTPUTDIR}/transcripts.allGene_cuff.fasta.fai ]; then
  echo "rm -rf ${OUTPUTDIR}/transcripts.allGene_cuff.fasta.fai"
  rm -rf ${OUTPUTDIR}/transcripts.allGene_cuff.fasta.fai
fi


echo "${BEDTOOLS_PATH}/fastaFromBed -fi ${OUTPUTDIR}/transcripts.allGene_cuff.fasta -bed ${OUTPUTDIR}/juncContig_allGene_cuff.bed -fo ${OUTPUTDIR}/juncContig_allGene_cuff.txt -tab -name -s"
${BEDTOOLS_PATH}/fastaFromBed -fi ${OUTPUTDIR}/transcripts.allGene_cuff.fasta -bed ${OUTPUTDIR}/juncContig_allGene_cuff.bed -fo ${OUTPUTDIR}/juncContig_allGene_cuff.txt -tab -name -s
check_error $?


echo "perl ${COMMAND_FUSION}/summarizeExtendedContig.pl ${OUTPUTDIR}/juncList_anno7.txt ${OUTPUTDIR}/juncContig_allGene_cuff.txt | uniq > ${OUTPUTDIR}/comb2eContig.txt"
perl ${COMMAND_FUSION}/summarizeExtendedContig.pl ${OUTPUTDIR}/juncList_anno7.txt ${OUTPUTDIR}/juncContig_allGene_cuff.txt | uniq > ${OUTPUTDIR}/comb2eContig.txt
check_error $?

echo "perl ${COMMAND_FUSION}/psl2inframePair.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${OUTPUTDIR}/comb2inframe.txt"
perl ${COMMAND_FUSION}/psl2inframePair.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${OUTPUTDIR}/comb2inframe.txt
check_error $?

echo "perl ${COMMAND_FUSION}/psl2geneRegion.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${OUTPUTDIR}/comb2geneRegion.txt"
perl ${COMMAND_FUSION}/psl2geneRegion.pl ${OUTPUTDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${OUTPUTDIR}/comb2geneRegion.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno7.txt ${OUTPUTDIR}/comb2eContig.txt 2 > ${OUTPUTDIR}/juncList_anno8.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno7.txt ${OUTPUTDIR}/comb2eContig.txt 2 > ${OUTPUTDIR}/juncList_anno8.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno8.txt ${OUTPUTDIR}/comb2inframe.txt 1 > ${OUTPUTDIR}/juncList_anno9.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno8.txt ${OUTPUTDIR}/comb2inframe.txt 1 > ${OUTPUTDIR}/juncList_anno9.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno9.txt ${OUTPUTDIR}/comb2geneRegion.txt 2 > ${OUTPUTDIR}/juncList_anno10.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${OUTPUTDIR}/juncList_anno9.txt ${OUTPUTDIR}/comb2geneRegion.txt 2 > ${OUTPUTDIR}/juncList_anno10.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addHeader.pl ${OUTPUTDIR}/juncList_anno10.txt > ${OUTPUTDIR}/${TAG}.fusion.txt"
perl ${COMMAND_FUSION}/addHeader.pl ${OUTPUTDIR}/juncList_anno10.txt > ${OUTPUTDIR}/${TAG}.fusion.txt
check_error $?


