# Testing

This repository is automatically tested for correctness and consistency upon every pull request and merge. These sanity checks help to ensure that the content may be modified with confidence by anyone interested in making a contribution. Likewise, they aid reviewers by setting a minimum bar for content requirements.

As this repository is publicly hosted on GitHub, we utilized GitHub Actions to perform these tests. Currently we test for:
- Spelling
- Link Validity
- Orphaned Content

## Spelling

This check utilizes the [cspell](https://github.com/streetsidesoftware/cspell) spell checker for code. This utility was chosen as it has wide platform support and will accommodate both CI/CD testing as well as IDE-based inline checking during authorship. It is currently utilizing an `en` and `en-US` dictionary, but custom dictionary words may be added to the [wordlist.txt](./wordlist.txt) file. Any word appended to this file will automatically be cleared for spelling.

As this content often includes code snippets and other structures that may not be well-suited for spelling checks, there are some ways to selectively disable spelling checks from within the content itself.

All [Markdown Code](https://www.markdownguide.org/basic-syntax/#code) is automatically exempt from spell checking. For example, in the following Markdown snippet, "kubectl" would be exempt from a spelling check:

````markdown
First execute the `kubectl` command.
````

For larger blocks of [Markdown Code Blocks](https://www.markdownguide.org/basic-syntax/#code-blocks) you will need to add an additional directive to disable and enable spell checking:

````markdown
<!-- /* cSpell:disable */ -->
```bash
export FOO=bar
export BAR=foo 
```
<!-- /* cSpell:enable */ -->
````

This will disable all spell checking with the disable/enable block.

## Link Validity

As Markdown content makes heavy use of links, we check all commits for valid links; both internal to the content as well as those that are public. This ensures that as we reference materials with the repository (ie. images and/or other Markdown docs), we can be sure that users will not be brought to missing content. Similarly, this check will ensure that all external links are currently reachable from a public perspective. 

## Orphaned Content

This check searches the repository for files that are no longer referenced by the content itself. The intention is to identify any content that may not require further maintenance and, therefore, may be removed from the repository.

# Running Tests

Because these tests are defined as GitHub Actions, the most convenient way to execute them locally is by utilizing the `act` command line utility. This tool allows for the execution of the full suite of tests in parallel or selective execution of specific tests. And, because these tests are identical to those that will be run for every pull request, you can commit with confidence that your content will be reviewed in a timely manner.

To execute locally, follow the [installation instructions](https://github.com/nektos/act#installation) for your platform.

Running the full suite of tests is as simple as executing:

```bash
$ act
```

from the top-level repository directory.

Alternatively, you may execute specific parts of the test suite with:

```bash
$ act -j <spell-check|link-check|orphaned-content-check>
```

You can also use Docker Compose to run these tests if you wish to not install `act`.
Run this command to do so after installing Docker Compose:

```sh
docker-compose run --rm tests
```

This will execute all of the tests that are executed by GitHub Actions.

