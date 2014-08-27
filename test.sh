#!/bin/sh

# Exit whenever a command fails
set -e

short_story_run_test() {
    local directory fixture expected infile outfile

    directory="$1"

    fixture="$directory/fixture.xml"
    expected="$directory/expected.xml"
    stylesheet="$directory/stylesheet.xsl"
    result="$(mktemp --tmpdir short-story-test.XXXXXXXXXX)"

    xsltproc -o "$result" "$stylesheet" "$fixture"

    diff -u "$result" "$expected" && echo "ok" && rm -f "$result"
}

for d in test/*; do
    echo Running tests in $d
    short_story_run_test $d
done
