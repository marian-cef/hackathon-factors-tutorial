# Source-side factors experiment step-by-step guide

To run the experiment, make sure your `.env` has `EXPERIMENT=source_factors_only` set, and then run the following from the main directory of the repo:

```
./run_end_to_end.sh
```

For the purposes of this tutorial, however, you may wish to run each step individually.

### Preprocessing

This will first run preprocessing. Preprocessing steps are as follows:

1. Tokenization using the Moses tokenizer
2. Escaping of special characters (`#:_\|`) that are used by the factored vocabulary format. See the [original documentation](https://github.com/marian-nmt/marian-dev/blob/master/doc/factors.md#other-requirements).
3. Addition of factors denoting capitalization information (`c0`, `c1`, `c2`, `c3`). See script description [below](#add-capitalization-factors).
4. Removal of the factors from the data (so the factors don't interfere with training/applying BPE). Later the factors are extended to the subworded text.
5. Training of BPE (train data only) using [subword-nmt](https://github.com/rsennrich/subword-nmt) on `train.tok.nofact.de` and `train.tok.en`. We train a joint vocabulary and use 32000 merge operations.
6. Application of BPE using a vocabulary threshold of 50.
7. Extension of factors to BPE splits. See script description [below](#transfer-factors-to-bpe).
8. Creation of regular joint-vocabulary using [`marian-vocab`](https://marian-nmt.github.io/docs/cmd/marian-vocab/) (train data only), on `train.tok.nofact.bpe.de` and `train.tok.bpe.en`.
9. Creation of factored vocabulary. For more information on factored vocabularies in Marian, see the [original documentation](https://github.com/marian-nmt/marian-dev/blob/master/doc/factors.md#create-the-factored-vocabulary). For script details see [below](#create-factored-vocabulary).


For code, see the scripts [`preprocess_train.sh`](../scripts/source_factors_only/preprocess_train.sh) and [`preprocess_test.sh`](../scripts/source_factors_only/preprocess_test.sh).

### Training

After preprocessing the train and valid sets, training will run. See [`train_model.sh`](../scripts/source_factors_only/train_model.sh). For a detailed description of training options, see the [original documentation](https://github.com/marian-nmt/marian-dev/blob/master/doc/factors.md#training-options).

Important hyperparameters to note in our training setup:

```
$MARIAN/marian -m $MODEL_DIR/model.npz \
                -t $DATA/$TRAIN_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.bpe.$TGT_LANG \ # Factors in source only
                --valid-sets $DATA/$VALID_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$VALID_PREFIX.tok.bpe.$TGT_LANG \
                -v $DATA/vocab.$SRC_LANG$TGT_LANG.fsv $DATA/vocab.$SRC_LANG$TGT_LANG.yml \ # .fsv as source vocab, .yml as target
                ...
                --tied-embeddings-all \ # For source-side factors only, weight tying only works with concatenation, or with dummy factors if summing (see docs)
                ...
                --factors-dim-emb 8 \ # Embedding size of factors, only used for concat
                --factors-combine concat \ # How to combine factor and lemma embeddings (concat or sum)
                ...
```

Training with this setup will take several hours on GPU. For the purposes of this tutorial, once you are satisfied that training and validation are running properly, you may use the pre-trained model inside [`pre-trained-model/`](pre-trained-model/). 

### Inference

If you are using the provided pre-trained model, first change `MODEL_DIR` in the `.env` to the following (if you are using your own model, skip this step):

```
MODEL_DIR=$REPO_ROOT/$EXPERIMENT/pre-trained-model
```

Preprocess the test set:

```
$SCRIPTS/$EXPERIMENT/preprocess_test.sh -p $TEST_PREFIX
```

Then run inference:

```
$SCRIPTS/translate.sh
```

Finally, run postprocessing. This applies the following steps:

1. De-BPE
2. De-escaping special characters (`#:_\|`)
3. Detokenization

```
$SCRIPTS/$EXPERIMENT/postprocess.sh -p $TEST_PREFIX
```

### Evaluation

We run BLEU (using sacrebleu) on the translation output.

```
$SCRIPTS/$EXPERIMENT/evaluate_bleu.sh -p $TEST_PREFIX
```

You should get ~32 BLEU.

---

## Scripts

### Add capitalization factors

[`add_capitalization_factors.py`](../scripts/add_capitalization_factors.py)

Adds capitalization factors described in the main [README](../README.md#summary) to each word, separated by a pipe (`|`). The output file name will have the format `[input_file_prefix].fact.[lang]`.

#### Usage

```
usage: add_capitalization_factors.py [-h] -i INPUT_FILE -o OUTPUT_FILE
                                     [--factor_prefix FACTOR_PREFIX]

Adds capitalization factors to a file with tokenized text

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input_file INPUT_FILE
                        source file path
  -o OUTPUT_FILE, --output_file OUTPUT_FILE
                        output file path
  --factor_prefix FACTOR_PREFIX
                        prefix for the capitalization factors. Factors vocab
                        will be [|prefix0, |prefix1, |prefix2]. Default=c
```

### Transfer factors to BPE

[`transfer_factors_to_bpe.py`](../scripts/transfer_factors_to_bpe.py)

Given a tokenized file with factors applied, and the same data without factors but BPE-split, this script extends the factor of each token to all of its subword tokens. Going back to the example in the main README, if the tokenized, factored sentence is

```
yesterday|c1 ,|c3 i|c1 walked|c0 to|c0 ikea|c2 and|c0 bought|c0 some|c0 kallax|c1 shelves|c0 .|c3
```

and the BPE'd sentence is

```
yester@@ day , i walk@@ ed to i@@ k@@ ea and bought some kall@@ ax shelves .
```

the output of this script would be

```
yester@@|c1 day|c1 ,|c3 i|c1 walk@@|c0 ed|c0 to|c0 i@@|c2 k@@|c2 ea|c2 and|c0 bought|c0 some|c0 kall@@|c1 ax|c1 shelves|c0 .|c3
```

#### Usage

```
usage: transfer_factors_to_bpe.py [-h] --factored_corpus FACTORED_CORPUS
                                  --bpe_corpus BPE_CORPUS --output_file
                                  OUTPUT_FILE

Extend BPE splits to factored corpus

optional arguments:
  -h, --help            show this help message and exit
  --factored_corpus FACTORED_CORPUS
                        File with factors
  --bpe_corpus BPE_CORPUS
                        File with bpe splits
  --output_file OUTPUT_FILE, -o OUTPUT_FILE
                        output file path
```

### Create factored vocabulary

[`create_factored_vocab.sh`](../scripts/create_factored_vocab.sh)

Given a "regular" `yml` vocabulary and a factor prefix, created a factored vocabulary (`.fsv`). Currently the factor group needs to be specified manually:

```
${factor_prefix}0 : _${factor_prefix}
${factor_prefix}1 : _${factor_prefix}
${factor_prefix}2 : _${factor_prefix}
${factor_prefix}3 : _${factor_prefix}"
```

#### Usage

```
./create_factored_vocab.sh -i [YML_VOCAB] -o [VOCAB].fsv -p [FACTOR_PREFIX]
```
