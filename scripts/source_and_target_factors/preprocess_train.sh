#!/bin/bash

# exit if something wrong happens
set -e


# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../../.env


# Tokenize
echo "Tokenizing..."
cat $DATA/$TRAIN_PREFIX.$SRC_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $SRC_LANG > $DATA/$TRAIN_PREFIX.tok.$SRC_LANG
cat $DATA/$TRAIN_PREFIX.$TGT_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $TGT_LANG > $DATA/$TRAIN_PREFIX.tok.$TGT_LANG


# Escape special characters so that we can use factors in marian
echo "Escaping special characters..."
sed -i $DATA/$TRAIN_PREFIX.tok.$SRC_LANG -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/|/\&ppe;/g' -e 's/\\/\&esc;/g'
sed -i $DATA/$TRAIN_PREFIX.tok.$TGT_LANG -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/|/\&ppe;/g' -e 's/\\/\&esc;/g'


# Add factors denoting capitalization information
echo "Adding capitalization factors..."
python $SCRIPTS/add_capitalization_factors.py --input_file $DATA/$TRAIN_PREFIX.tok.$SRC_LANG --output_file $DATA/$TRAIN_PREFIX.tok.fact.$SRC_LANG --factor_prefix $FACTOR_PREFIX
python $SCRIPTS/add_capitalization_factors.py --input_file $DATA/$TRAIN_PREFIX.tok.$TGT_LANG --output_file $DATA/$TRAIN_PREFIX.tok.fact.$TGT_LANG --factor_prefix $FACTOR_PREFIX


# We remove the factors from the annotated data to apply BPE, and later we extend the factors to the subworded text
cat $DATA/$TRAIN_PREFIX.tok.fact.$SRC_LANG | sed "s/|${FACTOR_PREFIX}[0-9]//g" > $DATA/$TRAIN_PREFIX.tok.nofact.$SRC_LANG
cat $DATA/$TRAIN_PREFIX.tok.fact.$TGT_LANG | sed "s/|${FACTOR_PREFIX}[0-9]//g" > $DATA/$TRAIN_PREFIX.tok.nofact.$TGT_LANG

# Train BPE
echo "Training BPE..."
subword-nmt learn-joint-bpe-and-vocab --input $DATA/$TRAIN_PREFIX.tok.nofact.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.nofact.$TGT_LANG -s 32000 -o $DATA/$SRC_LANG$TGT_LANG.bpe --write-vocabulary $DATA/vocab.bpe.$SRC_LANG $DATA/vocab.bpe.$TGT_LANG


# Apply BPE
echo "Applying BPE..."
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$SRC_LANG --vocabulary-threshold 50 < $DATA/$TRAIN_PREFIX.tok.nofact.$SRC_LANG > $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$TGT_LANG --vocabulary-threshold 50 < $DATA/$TRAIN_PREFIX.tok.nofact.$TGT_LANG > $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG


# Extend BPE splits to factored corpus
echo "Applying BPE to factored corpus..."
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $DATA/$TRAIN_PREFIX.tok.fact.$SRC_LANG --bpe_corpus $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG --output_file $DATA/$TRAIN_PREFIX.tok.fact.bpe.$SRC_LANG
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $DATA/$TRAIN_PREFIX.tok.fact.$TGT_LANG --bpe_corpus $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG --output_file $DATA/$TRAIN_PREFIX.tok.fact.bpe.$TGT_LANG


# Create regular joint vocab
echo "Creating vocab..."
cat $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG | $MARIAN/marian-vocab > $DATA/vocab.$SRC_LANG$TGT_LANG.yml


# Create factored vocab
echo "Creating factored vocab..."
cat $DATA/vocab.$SRC_LANG$TGT_LANG.yml | sed 's/\"//g;s/:.*//g' > $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp # makes the regular vocab only a token per line
$SCRIPTS/create_factored_vocab.sh -i $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp -o $DATA/vocab.$SRC_LANG$TGT_LANG.fsv -p $FACTOR_PREFIX
rm $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp

# Exit success
exit 0
