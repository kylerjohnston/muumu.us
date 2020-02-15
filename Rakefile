#!/usr/bin/env ruby

require 'html-proofer'

task :test do
  sh "bundle exec jekyll build"
  options = {
    assume_extension: true,
    check_favicon: true,
    check_html: true,
    enforce_https: true
  }
  HTMLProofer.check_directory("./_site", options).run
end
