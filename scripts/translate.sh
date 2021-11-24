#!/bin/bash

# exit if something wrong happens
set -e

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../.env


# Translate test data
echo "Translating test data..."
$MARIAN/marian-decoder -c $MODEL_DIR/model.npz.best-translation.npz.decoder.yml \
                -i $DATA/$TEST_PREFIX.tok.bpe.$SRC_LANG \
                -o $DATA/$TEST_PREFIX.hyps.$TGT_LANG


# Exit success
exit 0
