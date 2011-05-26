#!/bin/sh

xsltproc icml-preproc.xsl test-source-1.icml |
    xsltproc icml-to-smd-rules.xsl -
