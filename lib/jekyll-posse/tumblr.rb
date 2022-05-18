require 'rest-client'

module JekyllPosse
  class TumblrPosse

    def initialize(data, content, blog, download = false)
      @data = data
      @content = content
      @blog = blog
      @download = download
      @token = ENV["TUMBLR_BEARER_TOKEN"]
    end

    def notes
      payload = {"body": @content}
      post = RestClient.post "https://api.tumblr.com/v2/blog/#{@blog}/post", payload.to_json, {:content_type => :json, :Authorization => "Bearer #{@token}"}
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
