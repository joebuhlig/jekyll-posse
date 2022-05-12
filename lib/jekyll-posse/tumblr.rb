require 'rest-client'

module JekyllPosse
  class TumblrPosse

    def initialize(data, content, blog)
      @data = data
      @content = content
      @blog = blog
      @token = get_bearer_token
      puts @token
    end

    def notes
      payload = {"body": @content}
      info = RestClient.get "https://api.tumblr.com/v2/user/info/", {:Authorization => @token}
      puts info
      post = RestClient.post "https://api.tumblr.com/v2/blog/#{@blog}/post", payload.to_json, {:content_type => :json, :Authorization => @token}
      puts post
      format_post(post.body)
    end

    def replies
    end

    def reposts
    end

    def likes
    end

    def photos
    end

    def videos
    end

    private
    def format_post(post)
      post = JSON.parse(post)
      return "https://#{@blog}/#{post["response"]["id_string"]}/"
    end

    def get_bearer_token()
      token = ENV["TUMBLR_BEARER_TOKEN"]
      return "Bearer #{token}"
    end

  end
end
