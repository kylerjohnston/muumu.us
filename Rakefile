#!/usr/bin/env ruby

require 'html-proofer'

task :test do
  sh "bundle exec jekyll build"
  options = {
    assume_extension: true,
    check_favicon: true,
    check_html: true,
    url_ignore: [
      /(api|accounts)\.spotify\.com/,
      'https://localhost/'
    ],
    hydra: {
      # Failing with timeouts if this is not set.
      # This number could be finessed more, if I need to speed up tests.
      max_concurrency: 5
    }
  }
  HTMLProofer.check_directory("./_site", options).run
end
