require 'nokogiri'
require 'minitest/autorun'

def find_posts(dir)
  posts = []
  Dir.each_child(dir) do |child|
    posts += find_posts(dir + "/#{child}") if File.directory?(dir + "/#{child}")
    posts.append(dir + "/#{child}") if child.end_with?('.html')
  end
  posts
end

class TestTags < Minitest::Test
  def test_all_posts_have_tags
    year_dirs = Dir.children('_site').select { |f| f.start_with?('20') }
    year_dirs.each do |year_dir|
      posts = find_posts("_site/#{year_dir}")
      posts.each do |post|
        doc = Nokogiri::HTML.parse(open(post))
        tags = doc.css('a.post_tag')
        assert tags.length.positive?
      end
    end
  end
end
