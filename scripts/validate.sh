#!/bin/bash
# validate.sh

bash /mnt/shared/home/christine/marian-eu-project-factors-tutorial/scripts/postprocess_valid.sh $1 2>errors.txt
comet-score -s /mnt/shared/home/christine/marian-eu-project-factors-tutorial/source_factors_only/data/valid.de \
    -t /mnt/shared/home/christine/marian-eu-project-factors-tutorial/valid.hyps.debpe.detok \
    -r /mnt/shared/home/christine/marian-eu-project-factors-tutorial/source_factors_only/data/valid.en \
    --model wmt21-cometinho-da > comet_score 2>>errors.txt
cat comet_score | tail -1 | awk '/[0-9]+\.[0-9]+$/ {print $NF}'
