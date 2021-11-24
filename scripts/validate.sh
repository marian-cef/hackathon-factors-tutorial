#!/bin/bash
# validate.sh

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../.env

bash $SCRIPTS/postprocess_valid.sh $1 2>errors.txt
comet-score -s $DATA/valid.de \
    -t valid.hyps.debpe.detok \
    -r $DATA/valid.en \
    --model wmt21-cometinho-da > comet_score 2>>errors.txt
cat comet_score | tail -1 | awk '/[0-9]+\.[0-9]+$/ {print $NF}'
