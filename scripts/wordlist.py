import argparse
import sys

# sort wordlist and remove any empty lines/duplicats
def _list_sort(c):
    c = set([i for i in c if i])
    return sorted(c, key=lambda s: s.lower())


def sort(wordlist):
    with open(wordlist, "r+") as fh:
        c = fh.read().split("\n")
        s = _list_sort(c)
        fh.seek(0)
        fh.truncate()
        fh.write("\n".join(s))
    return 0


def check(wordlist):
    with open(wordlist, 'r') as fh:
        c = fh.read().split("\n")
        s = _list_sort(c)
        if c == s:
            print("Wordlist is sorted.")
            return 0

        sys.stderr.write("ERROR: Wordlist is not sorted.\n"
                         "Run `python scripts/wordlist.py "
                         "sort <wordlist>` to correct.\n")
        return -1


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()

    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("wordlist")
    check_parser.set_defaults(f=check)

    sort_parser = subparsers.add_parser("sort")
    sort_parser.add_argument("wordlist")
    sort_parser.set_defaults(f=sort)

    args = parser.parse_args()
    rc = args.f(args.wordlist)
    sys.exit(rc)


if __name__ == '__main__':
    main()
