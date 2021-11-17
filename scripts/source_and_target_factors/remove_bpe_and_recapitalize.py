import os
import argparse


def main():
    args = parse_user_args()

    factored_file = os.path.realpath(args.factored_subwords)
    output_file = os.path.realpath(args.output_file)
    bpe_separator = args.bpe_seperator
    factor_prefix = args.factor_prefix

    with open(factored_file, 'r', encoding='utf-8') as f_factored, \
         open(output_file, 'w', encoding='utf-8') as f_output:

         for l_fact in f_factored:

            l_fact_toks = l_fact.strip().split()
            recased_words = []

            current_word = []
            for fact_tok in l_fact_toks:
                subword, current_factor = get_subword_and_factor(fact_tok)
               	if subword[-2:] != bpe_separator:
                    current_word.append(subword)
                    recased_word = recase_by_factor("".join(current_word), current_factor, factor_prefix)
                    recased_words.append(recased_word)
                    current_word = []
                else:
                    current_word.append(subword[:-2])
            if current_word:
                recased_word = recase_by_factor("".join(current_word), current_factor, factor_prefix)
                recased_words.append(recased_word)

            f_output.write(' '.join(recased_words) + '\n')


def get_subword_and_factor(token):
    separator_idx = token.index("|")
    return token[:separator_idx], token[separator_idx + 1:]

def recase_by_factor(token, factor, factor_prefix):
    if factor == f"{factor_prefix}0":
        return token.lower()
    elif factor == f"{factor_prefix}1":
        return token.title()
    elif factor == f"{factor_prefix}2":
        return token.upper()
    else:
        return token


def parse_user_args():
    parser = argparse.ArgumentParser(description='Remove BPE and recapitalize tokens based on factors')
    parser.add_argument('--factored_subwords', required=True, help='File with factors')
    parser.add_argument('--output_file', '-o', required=True, help='output file path')
    parser.add_argument('--bpe_seperator', required=False, default="@@", help='BPE separator')
    parser.add_argument('--factor_prefix', required=False, default="c", help='Factor prefix')
    return parser.parse_args()


if __name__ == "__main__":
    main()