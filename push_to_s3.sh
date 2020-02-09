#!/usr/bin/env bash

set -e

aws --profile muumuus s3 sync --delete _site/ s3://muumu.us
