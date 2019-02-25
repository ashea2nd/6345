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

AM_dir=mono_t9
one=$1
two=$2
three=$3
four=$4
five=$5

echo ============================================================================
echo "                     MonoPhone Training & Decoding                        "
echo ============================================================================

steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd"  --realign_iters="'$one' '$two' '$three' '$four' '$five'" data/train_1k data/lang exp/"$AM_dir"

utils/mkgraph.sh --mono data/lang_test_bg exp/"$AM_dir" exp/"$AM_dir"/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/"$AM_dir"/graph data/test_100 exp/"$AM_dir"/decode_test

bash RESULTS "$AM_dir"

echo ============================================================================
echo "Successfully finished training monophone AM on" `date`
echo ============================================================================

exit 0
