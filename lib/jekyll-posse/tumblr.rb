require 'tumblr_client'
require 'rest-client'

module JekyllPosse
  class TumblrPosse

    def initialize(data = nil, content = nil, blog = nil, download = false)
      @data = data
      @content = content
      @blog = blog
      @download = download

      Tumblr.configure do |config|
        config.consumer_key = ENV["TUMBLR_CONSUMER_KEY"]
        config.consumer_secret = ENV["TUMBLR_CONSUMER_SECRET"]
        config.oauth_token = ENV["TUMBLR_ACCESS_TOKEN"]
        config.oauth_token_secret = ENV["TUMBLR_ACCESS_TOKEN_SECRET"]
      end

      @client = Tumblr::Client.new
    end

    def notes
      post = @client.text(@blog, {:body => @content})
      format_post(post)
    end

    def replies
    end

    def reposts
    end

    def likes
    end

    def photos
      post = @client.photo(@blog, {:data => [@data["photo"][0]["url"]]})
      format_post(post)
    end

    def videos
    end

    def format_post(post)
      id = post["id_string"]
      return "https://#{@blog}/#{id}/"
    end

    def download_post(url)
    end

  end
end
