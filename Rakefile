#!/usr/bin/env ruby

require 'date'
require 'rake/testtask'

task :test do
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
      max_concurrency: 3
    }
  }

  Rake::TestTask.new do |task|
    task.pattern = '_test/*.rb'
  end
  #HTMLProofer.check_directory("./_site", options).run
end

task :publish do
  sh './push_to_s3.sh'
  sh './invalidate_cloudfront_cache.sh'
end

task :new do
  today = Date.today
  filename = "_drafts/#{today.strftime('%s')}.md"
  header = <<~END
  ---
  title: NEEDS A TITLE
  date: #{today.strftime('%Y-%m-%d')}
  layout: post
  excerpt:
  tags:
  - tag1
  ---
  END
  File.write(filename, header, mode: "a")
  puts "Wrote #{filename}"
end
