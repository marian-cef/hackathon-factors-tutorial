#!/bin/bash

# exit if something wrong happens
set -e

# Posprocessing steps (debpe, de-escape special characters, detokenize)
cat $1 | sed 's/@@ //g' > valid.hyps.debpe

cat valid.hyps.debpe \
    | sed -e 's/\&htg;/#/g' \
          -e 's/\&cln;/:/g' \
          -e 's/\&usc;/_/g' \
          -e 's/\&ppe;/|/g' \
          -e 's/\&esc;/\\/g' \
    | /mnt/shared/home/christine/marian-eu-project-factors-tutorial/tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l en \
    > valid.hyps.debpe.detok

# Exit success
exit 0
