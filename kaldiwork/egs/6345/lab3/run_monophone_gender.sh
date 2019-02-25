#!/bin/bash

#
# Copyright 2013 Bagher BabaAli,
#           2014 Brno University of Technology (Author: Karel Vesely)
#
# TIMIT, description of the database:
# http://perso.limsi.fr/lamel/TIMIT_NISTIR4930.pdf
#
# Hon and Lee paper on TIMIT, 1988, introduces mapping to 48 training phonemes,
# then re-mapping to 39 phonemes for scoring:
# http://repository.cmu.edu/cgi/viewcontent.cgi?article=2768&context=compsci
#

. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e

train_nj=4
decode_nj=4

AM_dir=mono_t10

echo ============================================================================
echo "                     MonoPhone Training & Decoding                        "
echo ============================================================================

awk "/ f/ { print $1 }" data/train_1k/spk2gender | tee train_f.txt
awk "/ f/ { print $1 }" data/test_100/spk2gender | tee test_f.txt

awk "/ m/ { print $1 }" data/train_1k/spk2gender | tee train_m.txt
awk "/ m/ { print $1 }" data/test_100/spk2gender | tee test_m.txt

sh utils/subset_data_dir.sh --spk-list train_f.txt data/train_1k data/train_1k_f
sh utils/subset_data_dir.sh --spk-list test_f.txt data/test_100 data/test_100_f

sh utils/subset_data_dir.sh --spk-list train_m.txt data/train_1k data/train_1k_m
sh utils/subset_data_dir.sh --spk-list test_m.txt data/test_100 data/test_100_m

declare -a MF=("m" "f")

for i in "${MF[@]}"
do
  :
  for j in "${MF[@]}"
  do
    :
    steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train_1k_"$i" data/lang exp/"$AM_dir"

    utils/mkgraph.sh --mono data/lang_test_bg exp/"$AM_dir" exp/"$AM_dir"/graph

    steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
     exp/"$AM_dir"/graph data/test_100_"$j" exp/"$AM_dir"/decode_test

    bash RESULTS "$AM_dir"

    echo ============================================================================
    echo "HERE!!!!!!!!!!!!!!!!!!!!!!!!ij $i $j"
    echo ============================================================================

  done
done

echo ============================================================================
echo "Successfully finished training monophone AM on" `date`
echo ============================================================================

exit 0
