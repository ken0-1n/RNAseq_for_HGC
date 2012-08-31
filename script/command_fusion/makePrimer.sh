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

readonly INPUTDIR=${OUTPUTDIR}/sequence
readonly FUSIONDIR=${OUTPUTDIR}/fusion
readonly CUFFDIR=${OUTPUTDIR}/cufflink


if [ -f ${CUFFDIR}/transcripts.gtf ]; then
  # convert .gtf fiile to .bed file
  echo "perl ${COMMAND_FUSION}/gtf2bed.pl ${CUFFDIR}/transcripts.gtf > ${FUSIONDIR}/transcripts.cuff.bed"
  perl ${COMMAND_FUSION}/gtf2bed.pl ${CUFFDIR}/transcripts.gtf > ${FUSIONDIR}/transcripts.cuff.bed
  check_error $?

  # extract sequence data from the above .bed file
  echo "${BEDTOOLS_PATH}/fastaFromBed -fi ${REF_FA} -bed ${FUSIONDIR}/transcripts.cuff.bed -fo ${FUSIONDIR}/transcripts.cuff.tmp.fasta -tab -name -s"
  ${BEDTOOLS_PATH}/fastaFromBed -fi ${REF_FA} -bed ${FUSIONDIR}/transcripts.cuff.bed -fo ${FUSIONDIR}/transcripts.cuff.tmp.fasta -tab -name -s
  check_error $?

  # concatinate the .fasta records whose sequences are the same
  echo "perl ${COMMAND_FUSION}/catSeq.pl ${FUSIONDIR}/transcripts.cuff.tmp.fasta > ${FUSIONDIR}/transcripts.cuff.fasta"
  perl ${COMMAND_FUSION}/catSeq.pl ${FUSIONDIR}/transcripts.cuff.tmp.fasta > ${FUSIONDIR}/transcripts.cuff.fasta
  check_error $?

  # gather the .fasta file for annotated genes and .fasta file for newly assembled transcriptome
  echo "cat ${ALLGENEREF} ${FUSIONDIR}/transcripts.cuff.fasta > ${FUSIONDIR}/transcripts.allGene_cuff.fasta"
  cat ${ALLGENEREF} ${FUSIONDIR}/transcripts.cuff.fasta > ${FUSIONDIR}/transcripts.allGene_cuff.fasta
  check_error $?

else
  echo "cp ${ALLGENEREF} ${FUSIONDIR}/transcripts.allGene_cuff.fasta"
  cp ${ALLGENEREF} ${FUSIONDIR}/transcripts.allGene_cuff.fasta
  check_error $?

fi

# mapping the contigs to the .fasta file
echo "${BLAT_PATH}/blat -maxIntron=5 ${FUSIONDIR}/transcripts.allGene_cuff.fasta ${FUSIONDIR}/juncContig.fa ${FUSIONDIR}/juncContig_allGene_cuff.psl"
${BLAT_PATH}/blat -maxIntron=5 ${FUSIONDIR}/transcripts.allGene_cuff.fasta ${FUSIONDIR}/juncContig.fa ${FUSIONDIR}/juncContig_allGene_cuff.psl
check_error $?


echo "perl ${COMMAND_FUSION}/psl2bed_junc.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl > ${FUSIONDIR}/juncContig_allGene_cuff.bed"
perl ${COMMAND_FUSION}/psl2bed_junc.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl > ${FUSIONDIR}/juncContig_allGene_cuff.bed
check_error $?

if [ -f ${FUSIONDIR}/transcripts.allGene_cuff.fasta.fai ]; then
  echo "rm -rf ${FUSIONDIR}/transcripts.allGene_cuff.fasta.fai"
  rm -rf ${FUSIONDIR}/transcripts.allGene_cuff.fasta.fai
fi


echo "${BEDTOOLS_PATH}/fastaFromBed -fi ${FUSIONDIR}/transcripts.allGene_cuff.fasta -bed ${FUSIONDIR}/juncContig_allGene_cuff.bed -fo ${FUSIONDIR}/juncContig_allGene_cuff.txt -tab -name -s"
${BEDTOOLS_PATH}/fastaFromBed -fi ${FUSIONDIR}/transcripts.allGene_cuff.fasta -bed ${FUSIONDIR}/juncContig_allGene_cuff.bed -fo ${FUSIONDIR}/juncContig_allGene_cuff.txt -tab -name -s
check_error $?


echo "perl ${COMMAND_FUSION}/summarizeExtendedContig.pl ${FUSIONDIR}/juncList_anno7.txt ${FUSIONDIR}/juncContig_allGene_cuff.txt | uniq > ${FUSIONDIR}/comb2eContig.txt"
perl ${COMMAND_FUSION}/summarizeExtendedContig.pl ${FUSIONDIR}/juncList_anno7.txt ${FUSIONDIR}/juncContig_allGene_cuff.txt | uniq > ${FUSIONDIR}/comb2eContig.txt
check_error $?

echo "perl ${COMMAND_FUSION}/psl2inframePair.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${FUSIONDIR}/comb2inframe.txt"
perl ${COMMAND_FUSION}/psl2inframePair.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${FUSIONDIR}/comb2inframe.txt
check_error $?

echo "perl ${COMMAND_FUSION}/psl2geneRegion.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${FUSIONDIR}/comb2geneRegion.txt"
perl ${COMMAND_FUSION}/psl2geneRegion.pl ${FUSIONDIR}/juncContig_allGene_cuff.psl ${DBDIR}/fusion/codingInfo.txt > ${FUSIONDIR}/comb2geneRegion.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno7.txt ${FUSIONDIR}/comb2eContig.txt 2 > ${FUSIONDIR}/juncList_anno8.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno7.txt ${FUSIONDIR}/comb2eContig.txt 2 > ${FUSIONDIR}/juncList_anno8.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno8.txt ${FUSIONDIR}/comb2inframe.txt 1 > ${FUSIONDIR}/juncList_anno9.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno8.txt ${FUSIONDIR}/comb2inframe.txt 1 > ${FUSIONDIR}/juncList_anno9.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno9.txt ${FUSIONDIR}/comb2geneRegion.txt 2 > ${FUSIONDIR}/juncList_anno10.txt"
perl ${COMMAND_FUSION}/addGeneral.pl ${FUSIONDIR}/juncList_anno9.txt ${FUSIONDIR}/comb2geneRegion.txt 2 > ${FUSIONDIR}/juncList_anno10.txt
check_error $?

echo "perl ${COMMAND_FUSION}/addHeader.pl ${FUSIONDIR}/juncList_anno10.txt > ${FUSIONDIR}/${TAG}.fusion.all.txt"
perl ${COMMAND_FUSION}/addHeader.pl ${FUSIONDIR}/juncList_anno10.txt > ${FUSIONDIR}/${TAG}.fusion.all.txt
check_error $?

echo "perl ${COMMAND_FUSION}/filterMaltiMap.pl ${FUSIONDIR}/${TAG}.fusion.all.txt > ${FUSIONDIR}/${TAG}.fusion.filt1.txt"
perl ${COMMAND_FUSION}/filterMaltiMap.pl ${FUSIONDIR}/${TAG}.fusion.all.txt > ${FUSIONDIR}/${TAG}.fusion.filt1.txt
check_error $?

echo "perl ${COMMAND_FUSION}/filterColumns.pl ${FUSIONDIR}/${TAG}.fusion.filt1.txt > ${FUSIONDIR}/${TAG}.fusion.txt"
perl ${COMMAND_FUSION}/filterColumns.pl ${FUSIONDIR}/${TAG}.fusion.filt1.txt > ${FUSIONDIR}/${TAG}.fusion.txt
check_error $?

