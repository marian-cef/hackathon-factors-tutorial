#!/bin/bash

# exit if something wrong happens
set -e

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../../.env


# Train Model
echo "Training started..."
mkdir -p $MODEL_DIR
$MARIAN/marian -m $MODEL_DIR/model.npz \
                -t $DATA/$TRAIN_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.fact.bpe.$TGT_LANG \
                --valid-sets $DATA/$VALID_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$VALID_PREFIX.tok.fact.bpe.$TGT_LANG \
                -v $DATA/vocab.$SRC_LANG$TGT_LANG.fsv $DATA/vocab.$SRC_LANG$TGT_LANG.fsv \
                --type transformer \
                --dec-depth 6 --enc-depth 6 \
                --dim-emb 512 \
                --transformer-dropout 0.1 \
                --transformer-dropout-attention 0.1 \
                --transformer-dropout-ffn 0.1 \
                --transformer-heads 8 \
                --transformer-preprocess "" \
                --transformer-postprocess "dan" \
                --transformer-dim-ffn 2048 \
                --tied-embeddings-all \
                --valid-mini-batch 8 \
                --valid-metrics bleu cross-entropy perplexity \
                --valid-log $MODEL_DIR/valid.log \
                --log $MODEL_DIR/train.log \
                --early-stopping 5 \
                --learn-rate 0.0003 \
                --lr-warmup 16000 \
                --lr-decay-inv-sqrt 16000 \
                --lr-report true \
                --exponential-smoothing 1.0 \
                --label-smoothing 0.1 \
                --optimizer-params 0.9 0.98 1.0e-09 \
                --optimizer-delay 2 \
                --keep-best \
                --overwrite \
                --mini-batch-fit \
                --sync-sgd \
                --devices $GPUS \
                --workspace 7000 \
                --factors-combine sum \
                --lemma-dependency soft-transformer-layer \
                --disp-freq 100 \
                --save-freq 500 \
                --valid-freq 500 \
                --beam-size 4 \
                --normalize 1.0 \


# Exit success
exit 0
