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
  def test_all_posts_have_tags_not_tag1
    year_dirs = Dir.children('_site').select { |f| f.start_with?('20') }
    year_dirs.each do |year_dir|
      posts = find_posts("_site/#{year_dir}")
      posts.each do |post|
        doc = Nokogiri::HTML.parse(open(post))
        tags = doc.css('a.post_tag')

        # Make sure all posts have tags
        assert tags.length.positive?

        tags.each do |tag|
          tag.children.each do |child|
            # Make sure the template tag `tag1` is not used
            assert child.content.include?('tag1') == false
          end
        end
      end
    end
  end
end
