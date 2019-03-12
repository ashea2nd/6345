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

feats_nj=10
train_nj=4
decode_nj=4

AM_dir=mono1

decode_only=0

if [ $decode_only -eq 0 ]; then

echo ============================================================================
echo "                Data & Lexicon & Language Preparation                     "
echo ============================================================================

# need to set location of TIMIT corpus on Athena (or elsewhere)
timit=/nobackup1c/users/mit-6345/6345_data/timit

local/timit_data_prep.sh $timit || exit 1

local/timit_prepare_dict.sh

# Caution below: we remove optional silence by setting "--sil-prob 0.0",
# in TIMIT the silence appears also as a word in the dictionary and is scored.
utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false --num-sil-states 3 \
 data/local/dict "sil" data/local/lang_tmp data/lang

local/timit_format_data.sh

utils/subset_data_dir.sh data/train 1000 data/train_1k
utils/subset_data_dir.sh data/test 100 data/test_100

echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc

for x in train_1k test_100; do 
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj data/$x exp/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done

echo ============================================================================
echo "                     MonoPhone Training & Decoding                        "
echo ============================================================================

steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train_1k data/lang exp/"$AM_dir"

fi

# create the language model
local/timit_prepare_lm.sh

utils/mkgraph.sh --mono data/lang_test exp/"$AM_dir" exp/"$AM_dir"/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/"$AM_dir"/graph data/test_100 exp/"$AM_dir"/decode_test

echo "Language model perplexity:"
ngram -lm data/local/nist_lm/lm_phone.arpa.gz -ppl data/local/data/lm_test.text

bash RESULTS "$AM_dir"

echo ============================================================================
echo "Successfully finished TIMIT phone recognition on" `date`
echo ============================================================================

exit 0
