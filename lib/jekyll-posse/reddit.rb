require 'rest-client'

module JekyllPosse
  class RedditPosse

    def initialize(data, content, sanitized, silo, download = false)
      @domain = "https://oauth.reddit.com/"
      @data = data
      @content = content
      @sanitized = sanitized
      @subreddit = get_subreddit(silo)
      @download = download
      @token = ENV["REDDIT_BEARER_TOKEN"]
    end

    def notes
      payload = {
        "api_type" => "json",
        "kind" => "self",
        "sr" => @subreddit,
        "text" => @content,
        "title" => create_title
      }
      post = RestClient.post "#{@domain}/api/submit", payload, {:Authorization => "Bearer #{@token}"}
      format_post(post)
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
      return JSON.parse(post)["json"]["data"]["url"]
    end

    def get_subreddit(silo)
      parts = silo.split('/')
      if parts[3] == 'u'
        subreddit = "u_#{parts[4]}"
      else
        subreddit = parts[4]
      end
      subreddit
    end

    def create_title
      @sanitized.split[0...11].join(' ')
    end

  end
end
