#!/bin/bash

# exit if something wrong happens
set -e

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../.env

# Posprocessing steps (debpe, de-escape special characters, detokenize)
cat $1 | sed 's/@@ //g' > valid.hyps.debpe

cat valid.hyps.debpe \
    | sed -e 's/\&htg;/#/g' \
          -e 's/\&cln;/:/g' \
          -e 's/\&usc;/_/g' \
          -e 's/\&ppe;/|/g' \
          -e 's/\&esc;/\\/g' \
    | $MOSES/scripts/tokenizer/detokenizer.perl -l en \
    > valid.hyps.debpe.detok

# Exit success
exit 0
