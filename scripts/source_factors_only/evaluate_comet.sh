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


# Evaluation steps (COMET)
comet-score -s $DATA/$TEST_PREFIX.$SRC_LANG -t $DATA/$TEST_PREFIX.hyps.debpe.detok.$TGT_LANG -r $DATA/$TEST_PREFIX.$TGT_LANG --model wmt20-comet-da > $DATA/comet_score
cat $DATA/comet_score | tail -1

# Exit success
exit 0
