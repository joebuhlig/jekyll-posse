require 'rest-client'

module JekyllPosse
  class TumblrPosse

    def initialize(data, content, blog)
      @data = data
      @content = content
      @blog = blog
      @token = ENV["TUMBLR_BEARER_TOKEN"]
    end

    def notes
      puts @content
      post = RestClient.post "https://api.tumblr.com/v2/blog/#{@blog}/post", {"body": @content}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
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

  end
end
