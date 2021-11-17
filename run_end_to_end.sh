#!/bin/bash

# exit when any command fails
set -e


# load variables
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $REPO_ROOT/.env


# check the existance of marian
if [ ! -e $MARIAN/marian ] || [ ! -e $MARIAN/marian-vocab ]; then
    echo "marian executable not found. You may have to setup the MARIAN variable with the path to the marian executable in the .env file"
    echo "Exiting..."
    exit 1
fi


# check the existance of input the files in the correct format
for prefix in $TRAIN_PREFIX $VALID_PREFIX $TEST_PREFIX; do
    for lang in $SRC_LANG $TGT_LANG; do
        test -e $DATA/$prefix.$lang || { echo "Error: File $DATA/$prefix.$lang file not found. Check your .env file. The file path must be \$DATA/\$PREFIX.\$LANG"; exit 1; }
    done
done


#########################
## end-to-end pipeline ##
#########################


# Preprocess training data
echo "Preprocessing train data..."
$SCRIPTS/$EXPERIMENT/preprocess_train.sh


# Preprocess valid data
echo "Preprocessing valid data..."
$SCRIPTS/$EXPERIMENT/preprocess_test.sh -p $VALID_PREFIX


# Train Model
$SCRIPTS/$EXPERIMENT/train_model.sh


# Preprocess test data
echo "Preprocessing test data..."
$SCRIPTS/$EXPERIMENT/preprocess_test.sh -p $TEST_PREFIX


# Translate test data
$SCRIPTS/translate.sh


# Postprocessing test data
echo "Postprocessing test data..."
$SCRIPTS/$EXPERIMENT/postprocess.sh -p $TEST_PREFIX


# Evaluate test data
echo "Evaluating test data..."
$SCRIPTS/$EXPERIMENT/evaluate_bleu.sh -p $TEST_PREFIX


# exit success
exit 0
