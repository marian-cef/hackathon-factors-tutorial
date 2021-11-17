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

# Posprocessing steps (debpe, de-escape special characters, detokenize)
cat $DATA/$prefix.hyps.$TGT_LANG | sed 's/@@ //g' > $DATA/$prefix.hyps.debpe.$TGT_LANG

cat $DATA/$prefix.hyps.debpe.$TGT_LANG \
    | sed -e 's/\&htg;/#/g' \
          -e 's/\&cln;/:/g' \
          -e 's/\&usc;/_/g' \
          -e 's/\&ppe;/|/g' \
          -e 's/\&esc;/\\/g' \
    | $MOSES/scripts/tokenizer/detokenizer.perl -l $TGT_LANG \
    > $DATA/$prefix.hyps.debpe.detok.$TGT_LANG

# Exit success
exit 0
