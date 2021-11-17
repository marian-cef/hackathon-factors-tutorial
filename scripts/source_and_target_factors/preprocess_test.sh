#!/bin/bash

# exit if something wrong happens
set -e

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../../.env


# parse options
while getopts ":p:" opt; do
  case $opt in
    p)
        prefix="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Validates files passed as argument
test -z $prefix && { echo "Missing Argument: file prefix needed (option -p)"; exit 1; }

test -e $DATA/$prefix.$SRC_LANG || { echo "Error: $DATA/$prefix.$SRC_LANG file not found."; exit 1; }
test -e $DATA/$prefix.$TGT_LANG || { echo "Error: $DATA/$prefix.$TGT_LANG file not found."; exit 1; }

# Tokenize
echo "Tokenizing..."
cat $DATA/$prefix.$SRC_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $SRC_LANG > $DATA/$prefix.tok.$SRC_LANG
cat $DATA/$prefix.$TGT_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $TGT_LANG > $DATA/$prefix.tok.$TGT_LANG


# Escape special characters so that we can use factors in marian
echo "Escaping special characters..."
sed -i $DATA/$prefix.tok.$SRC_LANG -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/|/\&ppe;/g' -e 's/\\/\&esc;/g'
sed -i $DATA/$prefix.tok.$TGT_LANG -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/|/\&ppe;/g' -e 's/\\/\&esc;/g'


# Add factors denoting capitalization information
echo "Adding capitalization factors..."
python $SCRIPTS/add_capitalization_factors.py --input_file $DATA/$prefix.tok.$SRC_LANG --output_file $DATA/$prefix.tok.fact.$SRC_LANG --factor_prefix $FACTOR_PREFIX
python $SCRIPTS/add_capitalization_factors.py --input_file $DATA/$prefix.tok.$TGT_LANG --output_file $DATA/$prefix.tok.fact.$TGT_LANG --factor_prefix $FACTOR_PREFIX


# We remove the factors from the annotated data to apply BPE, and later we extend the factors to the subworded text
cat $DATA/$prefix.tok.fact.$SRC_LANG | sed "s/|${FACTOR_PREFIX}[0-9]//g" > $DATA/$prefix.tok.nofact.$SRC_LANG
cat $DATA/$prefix.tok.fact.$TGT_LANG | sed "s/|${FACTOR_PREFIX}[0-9]//g" > $DATA/$prefix.tok.nofact.$TGT_LANG


# Apply BPE
echo "Applying BPE..."
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$SRC_LANG --vocabulary-threshold 50 < $DATA/$prefix.tok.nofact.$SRC_LANG > $DATA/$prefix.tok.nofact.bpe.$SRC_LANG
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$TGT_LANG --vocabulary-threshold 50 < $DATA/$prefix.tok.nofact.$TGT_LANG > $DATA/$prefix.tok.nofact.bpe.$TGT_LANG


# Extend BPE splits to factored corpus
echo "Applying BPE to factored corpus..."
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $DATA/$prefix.tok.fact.$SRC_LANG --bpe_corpus $DATA/$prefix.tok.nofact.bpe.$SRC_LANG --output_file $DATA/$prefix.tok.fact.bpe.$SRC_LANG
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $DATA/$prefix.tok.fact.$TGT_LANG --bpe_corpus $DATA/$prefix.tok.nofact.bpe.$TGT_LANG --output_file $DATA/$prefix.tok.fact.bpe.$TGT_LANG

# Exit success
exit 0
