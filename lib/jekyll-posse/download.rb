require 'jekyll'
require 'jekyll-posse/twitter'
require 'jekyll-posse/mastodon'
require 'jekyll-posse/tumblr'

module JekyllPosse
  class Download
    def self.process(args, options)
      if options["twitter"]
        twitter = JekyllPosse::TwitterPosse.new()
        twitter.download_tweet(args[0])
      end
    end
  end
end