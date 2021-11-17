import os
import argparse


def main():

    args = parse_user_args()

    input_file = os.path.realpath(args.input_file)
    output_file = os.path.realpath(args.output_file)
    factor_prefix = args.factor_prefix

    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:

        for sentence in f_in:
            factored_sentence = annotate_capitalization(sentence.strip(), factor_prefix)
            f_out.write(factored_sentence + "\n")

    # TODO: add logging


def annotate_capitalization(sentence, factor_prefix):
    '''
    Adds factors to each word in a sentence based on its capitalization.
    c0: all lowercase
    c1: Title Case
    c2: ALL UPPERCASE
    c3: oTHeR, non-alphabetic characters
    '''

    tokens_in = sentence.split()
    tokens_out = []
    for token in tokens_in:
        if token.lower() == token and token.isalpha():
            tokens_out.append(f"{token.lower()}|{factor_prefix}0")
        elif token.title() == token and token.isalpha():
            tokens_out.append(f"{token.lower()}|{factor_prefix}1")
        elif token.upper() == token and token.isalpha():
            tokens_out.append(f"{token.lower()}|{factor_prefix}2")
        else:
            tokens_out.append(f"{token.lower()}|{factor_prefix}3")

    return " ".join(tokens_out)


def parse_user_args():
    parser = argparse.ArgumentParser(description="Adds capitalization factors to a file with tokenized text")
    parser.add_argument('-i', '--input_file', help="source file path", required=True)
    parser.add_argument('-o', '--output_file', help="output file path", required=True)
    parser.add_argument('--factor_prefix', type=str, default='c', help="prefix for the capitalization factors. Factors vocab will be [|prefix0, |prefix1, |prefix2]")
    return parser.parse_args()


if __name__ == "__main__":
    main()
