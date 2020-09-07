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
    typhoeus: {
      connecttimeout: 30,
      timeout: 30
    },
    hydra: {
      # Failing with timeouts if this is not set.
      # This number could be finessed more, if I need to speed up tests.
      max_concurrency: 5
    }
  }
  HTMLProofer.check_directory("./_site", options).run
end

task :publish do
  sh 'push_to_s3.sh'
  sh 'invalidate_cloudfront_cache.sh'
end
