require 'jekyll'
require 'jekyll-posse/twitter'
require 'jekyll-posse/mastodon'
require 'jekyll-posse/tumblr'
require 'jekyll-posse/microblog'
require 'jekyll-posse/website'

module JekyllPosse
  class Download
    def self.process(args, options)
      if options["twitter"]
        twitter = JekyllPosse::TwitterPosse.new()
        twitter.download_tweet(args[0])
      elsif options["tumblr"]
        tumblr = JekyllPosse::TumblrPosse.new()
        tumblr.download_post(args[0])
      elsif options["instagram"]
        instagram = JekyllPosse::InstagramPosse.new()
        instagram.download_comment(args[0])
      elsif options["microblog"]
        microblog = JekyllPosse::MicroBlogPosse.new()
        microblog.download()
      elsif options["website"]
        website = JekyllPosse::WebsitePosse.new()
        website.download(args[0])
      end
    end
  end
end
