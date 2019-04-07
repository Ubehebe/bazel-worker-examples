from argparse import ArgumentParser

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--in", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    with open(vars(args).get('in')) as input:
        with open(args.out, 'w') as output:
            output.write(input.read())
