#!/bin/bash

# exit when any command fails
set -e

mkdir -p data
cd data

# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../.env

# download News Commentary
wget https://object.pouta.csc.fi/OPUS-News-Commentary/v16/moses/de-en.txt.zip
unzip de-en.txt.zip
paste News-Commentary.de-en.de News-Commentary.de-en.en | sed -r '/^\s*$/d' > pasted_corpus

# shuffle data
get_seeded_random() { seed="$1";  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null; }
shuf --random-source=<(get_seeded_random 1234) pasted_corpus > shuffled_corpus

cut -f 1 shuffled_corpus > full_corpus.de
cut -f 2 shuffled_corpus > full_corpus.en

# clean data
dir=$(pwd)
perl $MOSES/scripts/training/clean-corpus-n.perl $dir/full_corpus de en $dir/clean_corpus 1 50

# train dev test split
head -n 2000 clean_corpus.de > valid.de
head -n 4000 clean_corpus.de | tail -n 2000 > test.de
tail -n +4000 clean_corpus.de > train.de

head -n 2000 clean_corpus.en > valid.en
head -n 4000 clean_corpus.en | tail -n 2000 > test.en
tail -n +4000 clean_corpus.en > train.en

# remove extra files
rm de-en.txt.zip LICENSE News-Commentary.de-en.de News-Commentary.de-en.en News-Commentary.de-en.xml pasted_corpus README shuffled_corpus full_corpus.* clean_corpus.*

cd ..
