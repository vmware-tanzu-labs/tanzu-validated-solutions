import os
import re

# TODO: implement config file later
# CONFIG_FILE = "unlinked.cfg"
CONTENT_ROOT = "./src/"
EXCLUDED_FILES = [
    "./src/toc.md",
    "./src/VMwarePub.yaml",
]


class Config:

    def __init__(self, excluded_files=EXCLUDED_FILES,
                 content_root=CONTENT_ROOT):
        self.excluded_files = set(excluded_files)
        self.content_root = content_root


def get_all_repo_content():
    content = set()
    for dirname, _, files in os.walk(CONTENT_ROOT):
        for file in files:
            filename = os.path.join(dirname, file)
            content.add(filename)
    return content


def get_document_links(document):
    content = None
    with open(document) as fh:
        content = fh.read()

    # non-greedy search for all link structures like
    # [title](./img/foo.png). will strip any leading ./
    pattern = re.compile(r'\[.*?\]\(\.*\/*(.*?)\)')
    matches = pattern.findall(content)

    links = set()
    for match in matches:
        if match.startswith("http") or match.startswith("#"):
            continue
        links.add(match)
    return links


def main():
    config = Config()

    all_files = get_all_repo_content()

    doc_files = set(filter(lambda x: x.endswith(".md"), all_files))
    content_files = set(filter(lambda x: not x.endswith(".md"), all_files))

    linked_files = set()
    for doc_file in doc_files:
        file_directory = os.path.dirname(doc_file)
        links = get_document_links(doc_file)

        for link in links:
            content_path = os.path.join(file_directory, link)
            linked_files.add(content_path)

    unlinked_files = content_files - linked_files
    unlinked_files = unlinked_files - config.excluded_files

    if len(unlinked_files):
        print("Found the following unlinked %d file(s):" % len(unlinked_files))
        for unlinked_file in sorted(unlinked_files):
            print(unlinked_file)
        exit(-1)


if __name__ == '__main__':
    main()
