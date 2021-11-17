# 2021 MT Half-Marathon: Tutorial on Factored NMT Models in Marian

This is a tutorial on using factors in Marian for the 2021 MT Half-Marathon organized by the EU Marian Project members. For a comprehensive README on factors usage in marian, see the [docs](https://github.com/marian-nmt/marian-dev/blob/master/doc/factors.md). Much of the same information is summarized in this tutorial, but we recommend reading that document first. For more background on factors in NMT in general, see [Sennrich and Haddow (2016)](https://aclanthology.org/W16-2209/)[^1].

[^1]: Rico Sennrich and Barry Haddow. 2016. [Linguistic input features improve neural machine translation](https://aclanthology.org/W16-2209/). In Proceedings of the First Conference on Machine Translation (WMT16)

## Summary

The use case being tested for factors is replacing the truecaser, where instead capitalization information is encoded in a factor for each word. For example we have the sentence:

```
Yesterday, I walked to IKEA and bought some Kallax shelves.
```

With traditional truecasing, the preprocessed sentence might look like (after tokenization):

```
yesterday , I walked to IKEA and bought some Kallax shelves .
```

Using factors, the preprocessed sentence would look like

```
yesterday|c1 ,|c3 i|c1 walked|c0 to|c0 ikea|c2 and|c0 bought|c0 some|c0 kallax|c1 shelves|c0 .|c3
```

assuming we are using the following factors:

* `c0`: all lowercase word
* `c1`: Title case word (first letter capitalized, rest lowercase)
* `c2`: ALL UPPERCASE word
* `c3`: other (mixed casing, punctuation, numbers, etc.)

This tutorial provides two sets of scripts for training a factored NMT model, one with source-side factors only, and the other with both source- and target-side factors.

It uses a toy dataset from [NewsCommentary](https://opus.nlpl.eu/News-Commentary.php)[^2] for the language pair German-English.

[^2]: J. Tiedemann, 2012, [*Parallel Data, Tools and Interfaces in OPUS*](http://www.lrec-conf.org/proceedings/lrec2012/pdf/463_Paper.pdf). In Proceedings of the 8th International Conference on Language Resources and Evaluation (LREC 2012)

---

## Getting started

### Requirements

1. Python 3
2. Marian-dev precompiled, commit [4dd30b5065efba61fc044e9dc4303205c9d2ac53](https://github.com/marian-nmt/marian-dev/commit/4dd30b5065efba61fc044e9dc4303205c9d2ac53) or later. Please see the [Marian docs](https://marian-nmt.github.io/quickstart/) for a step-by-step guide.
3. `git clone` this repository.

### Setup

1. Create a python virtualenv and install the requirements:

```
python3[.X] -m venv tutorial-env
source tutorial-env/bin/activate
pip install -r requirements.txt
```

2. Install other dependencies (Moses scripts):
```
./install_dependencies.sh
```

3. Then edit the `MARIAN` path in the .env file in the main directory of this repo. Also change `EXPERIMENT` if you want to run the tutorial using both source- and target-side factors:

```
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Choose between source_factors_only OR source_and_target_factors
EXPERIMENT=source_factors_only

SCRIPTS=$REPO_ROOT/scripts
TOOLS=$REPO_ROOT/tools

MOSES=$TOOLS/moses-scripts
MARIAN= # Path to marian-dev build folder

DATA=$REPO_ROOT/$EXPERIMENT/data
TRAIN_PREFIX=train
VALID_PREFIX=valid
TEST_PREFIX=test

SRC_LANG=de
TGT_LANG=en

FACTOR_PREFIX=c

# Change if running inference with the pre-trained model
MODEL_DIR=$REPO_ROOT/$EXPERIMENT/models # $REPO_ROOT/$EXPERIMENT/pre-trained-model

GPUS="0"
```

### Data

Inside the `$EXPERIMENT/data` directory, there should be the following files:

```
test.de
test.en
train.de
train.en
valid.de
valid.en
```

To see how they were created, check the [`prepare_corpus.sh`](prepare_corpus.sh) script.

Now you're ready to run the experiments! For more detail on each one, go to the directory for that experiment. (But note that the `run_end_to_end.sh` script should be called from the main directory of the repo.)

---
