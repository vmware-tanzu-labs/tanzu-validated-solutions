# Check for google-wrapped links that take the form:
# https://www.google.com/url?q=https://someother-link.com
#
# Run without arguments, this will check for wrapped links,
# Alternatively, with the `fix` subcommand, it will remove
# the google wrapping within a file.

import argparse
import glob
import re
import sys

from urllib.parse import urlparse, parse_qs


def find_markdown_links(markdown):
    r = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
    links = r.findall(markdown)
    return links


def is_google_wrapped(link):
    u = urlparse(link)
    if u.netloc.endswith("google.com") and u.path == "/url":
        return True
    return False


def fix(args):
    filename = args.filename
    inplace = args.inplace

    with open(filename, 'r+') as fh:
        content = fh.read()
        links = find_markdown_links(content)
        for link in links:
            if is_google_wrapped(link[1]):
                u = urlparse(link[1])
                qp = parse_qs(u.query)
                query_url = qp['q'][0]
                content = content.replace(link[1], query_url)

        if(inplace):
            fh.seek(0)
            fh.write(content)
            fh.truncate()
        else:
            print(content)


def check(args):
    files = glob.glob('./**/*.md', recursive=True)
    google_wrapped_links = {}
    for f in files:
        google_wrapped_links[f] = []
        with open(f, 'r') as fh:
            links = find_markdown_links(fh.read())
            for link in links:
                if is_google_wrapped(link[1]):
                    google_wrapped_links[f].append(link)

    failed = False
    for f, links in google_wrapped_links.items():
        if len(links):
            failed = True
            print("Google wrapped links in %s" % f)
            for link in links:
                print("- %s -> %s" % link)
            print()

    if failed:
        print("\n!!! You may resolve these wrapped links by executing "
              "`python ./tests/wrapped-links.py fix -i <filename>` "
              "against your local branch.")

    return failed


def main():
    parser = argparse.ArgumentParser(prog='wrapped-links')
    parser.set_defaults(func=check)

    subparsers = parser.add_subparsers(help='sub-command help')
    fix_parser = subparsers.add_parser('fix')
    fix_parser.add_argument('--inplace', '-i', action='store_true',
                            default=False, help="make changes in-place")
    fix_parser.add_argument('filename', type=str)
    fix_parser.set_defaults(func=fix)

    args = parser.parse_args()

    if args:
        rc = args.func(args)

    sys.exit(rc)


if __name__ == '__main__':
    main()
