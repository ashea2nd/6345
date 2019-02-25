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

# Acoustic model parameters
numLeavesTri1=2500
numGaussTri1=15000

train_nj=4
decode_nj=4

mono_dir=mono
AM_dir=tri1

echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas Training & Decoding               "
echo ============================================================================

steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
 data/train_1k data/lang exp/$mono_dir exp/${mono_dir}_ali

# Train tri1, which is deltas + delta-deltas, on train data.
steps/train_deltas.sh --cmd "$train_cmd" \
 $numLeavesTri1 $numGaussTri1 data/train_1k data/lang exp/${mono_dir}_ali exp/"$AM_dir"

utils/mkgraph.sh data/lang_test_bg exp/"$AM_dir" exp/"$AM_dir"/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/"$AM_dir"/graph data/test_100 exp/"$AM_dir"/decode_test

bash RESULTS "$AM_dir"

echo ============================================================================
echo "Successfully finished training triphone AM on" `date`
echo ============================================================================

exit 0
