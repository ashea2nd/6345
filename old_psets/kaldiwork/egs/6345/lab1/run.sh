#!/bin/bash

. ./cmd.sh

tidigits=/nobackup1c/users/mit-6345/6345_data/tidigits

# The following command prepares the data/{train,dev,test} directories.
local/tidigits_data_prep.sh $tidigits || exit 1;
local/tidigits_prepare_lang.sh  || exit 1;
utils/validate_lang.pl data/lang/ # Note; this actually does report errors,
   # and exits with status 1, but we've checked them and seen that they
   # don't matter (this setup doesn't have any disambiguation symbols,
   # and the script doesn't like that).

utils/subset_data_dir.sh data/train 1000 data/train_1k
utils/subset_data_dir.sh data/test 1000 data/test_1k

# Now make some features.
featdir=feats
for x in test_1k train_1k; do
 steps/make_plp.sh --cmd "$train_cmd" --nj 20 --config conf/mfcc.conf\
   data/$x exp/make_feats/$x $featdir || exit 1;
 steps/compute_cmvn_stats.sh --fake data/$x exp/make_feats/$x $featdir || exit 1;
done

steps/train_mono.sh  --nj 4 --cmd "$train_cmd" \
  data/train_1k data/lang exp/mono0a

 utils/mkgraph.sh --mono data/lang exp/mono0a exp/mono0a/graph && \
 steps/decode.sh --nj 10 --cmd "$decode_cmd" \
      exp/mono0a/graph data/test_1k exp/mono0a/decode

# Getting results [see RESULTS file]
for x in exp/*/decode*; do [ -d $x ] && grep SER $x/wer_* | utils/best_wer.sh; done
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
