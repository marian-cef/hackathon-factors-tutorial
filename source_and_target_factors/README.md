# Source- and target-side factors experiment step-by-step guide

To run the experiment, make sure your `.env` has `EXPERIMENT=source_and_target_factors` set, and then run the following from the main directory of the repo:

```
./run_end_to_end.sh
```

For the purposes of this tutorial, however, you may wish to run each step individually.

This README only covers differences from the source-side-factors-only case. For details, see the [README](../source_factors_only/README.md) for that experiment.

### Preprocessing

Preprocessing is the same as the source-only factors case, except that the factors-related steps are also applied to the target language data. The factored vocabulary `.fsv` file is used as both the source and target vocabulary.


For code, see the scripts [`preprocess_train.sh`](../scripts/source_and_target_factors/preprocess_train.sh) and [`preprocess_test.sh`](../scripts/source_and_target_factors/preprocess_test.sh).

### Training

See [`train_model.sh`](../scripts/source_and_target_factors/train_model.sh). For a detailed description of training options, see the [original documentation](https://github.com/marian-nmt/marian-dev/blob/master/doc/factors.md#training-options).

Important hyperparameters to note in our training setup:

```
$MARIAN/marian -m $MODEL_DIR/model.npz \
                -t $DATA/$TRAIN_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.fact.bpe.$TGT_LANG \ # Factors in source and target
                --valid-sets $DATA/$VALID_PREFIX.tok.fact.bpe.$SRC_LANG $DATA/$VALID_PREFIX.tok.fact.bpe.$TGT_LANG \
                -v $DATA/vocab.$SRC_LANG$TGT_LANG.fsv $DATA/vocab.$SRC_LANG$TGT_LANG.fsv \ # .fsv as both source and target vocab
                ...
                --tied-embeddings-all \ # Works with summing since we have both source and target factors (see docs)
                ...
                --factors-combine sum \ # How to combine factor and lemma embeddings (must use sum if using target factors)
                --lemma-dependency soft-transformer-layer \ # How to condition factor predictions on lemmas (see docs)
                ...
```

Training with this setup will take several hours on GPU. For the purposes of this tutorial, once you are satisfied that training and validation are running properly, you may use the pre-trained model inside [`pre-trained-model/`](pre-trained-model/). 

### Inference

Run preprocessing and inference on the test set the same way as in the source-factors experiment, setting `MODEL_DIR` in the `.env` accordingly if you are using the provided pre-trained model.

Then run postprocessing. The main difference here is that the first step recases the text, in addition to removing BPE. See script description [below](#remove-bpe-and-recapitalize).

### Evaluation

Evaluation is the same. Again, you should get ~32 BLEU (although slightly higher than if you only use source factors).

---

## Scripts

### Remove BPE and recapitalize

[`remove_bpe_and_recapitalize.py`](../scripts/source_and_target_factors/remove_bpe_and_recapitalize.py)

Recombines subwords split by BPE, and recases the full tokens based on the predicted factor, according to the factors described in the main [README](../README.md#summary).

#### Usage

```
usage: remove_bpe_and_recapitalize.py [-h] --factored_subwords FACTORED_SUBWORDS --output_file OUTPUT_FILE [--bpe_seperator BPE_SEPERATOR] [--factor_prefix FACTOR_PREFIX]

Remove BPE and recapitalize tokens based on factors

optional arguments:
  -h, --help            show this help message and exit
  --factored_subwords FACTORED_SUBWORDS
                        File with factors
  --output_file OUTPUT_FILE, -o OUTPUT_FILE
                        output file path
  --bpe_seperator BPE_SEPERATOR
                        BPE separator, default="@@"
  --factor_prefix FACTOR_PREFIX
                        Factor prefix, default="c"
```
