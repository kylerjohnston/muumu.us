#!/usr/bin/env bash

aws --profile muumuus cloudfront create-invalidation --distribution-id E1JLIALKAS239T --paths "/*"
