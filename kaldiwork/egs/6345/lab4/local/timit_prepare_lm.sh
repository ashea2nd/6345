#!/bin/bash

srcdir=data/local/data
lmdir=data/local/nist_lm

[ -f path.sh ] && . ./path.sh

cut -d' ' -f2- $srcdir/train.text | sed -e 's:^:<s> :' -e 's:$: </s>:' \
  > $srcdir/lm_train.text

cut -d' ' -f2- $srcdir/test.text | sed -e 's:^:<s> :' -e 's:$: </s>:' \
 > $srcdir/lm_test.text

ngram-count -text $srcdir/lm_train.text -order 1 -interpolate -lm $lmdir/lm_phone.arpa.gz || exit 1;

test=data/lang_test
mkdir -p $test
cp -r data/lang/* $test

gunzip -c $lmdir/lm_phone.arpa.gz | \
arpa2fst --disambig-symbol=#0 \
         --read-symbol-table=$test/words.txt - $test/G.fst || exit 1;
fstisstochastic $test/G.fst

echo "Succeeded in creating LM."
