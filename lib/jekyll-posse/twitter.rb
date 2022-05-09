require 'twitter'

module JekyllPosse
  class TwitterPosse

    def initialize(data, content)
      puts ENV
      @data = data
      @content = content
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token = ENV["TWITTER_ACCESS_TOKEN"]
        config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
      end
    end

    def notes
      tweet = @client.update(content)
      format_tweet(tweet)
    end

    def replies
      if @data["photo"]
        tweet = @client.update_with_media(content, File.new(@data["photo"]), in_reply_to_status: @data["in-reply-to"])
      elsif @data["video"]
        tweet = @client.update_with_media(content, File.new(@data["video"]), in_reply_to_status: @data["in-reply-to"])
      else
        tweet = @client.update(content, in_reply_to_status: @data["in-reply-to"])
      end
      format_tweet(tweet)
    end

    def reposts
      tweet = @client.retweet(@data["repost-of"])
      format_tweet(tweet[0])
    end

    def likes
      tweet = @client.favorite(@data["like-of"])
      format_tweet(tweet[0])
    end

    def photos
      tweet = @client.update_with_media(content, File.new(@data["photo"]))
      format_tweet(tweet)
    end

    def videos
      tweet = @client.update_with_media(content, File.new(@data["video"]))
      format_tweet(tweet)
    end

    private
    def format_tweet(tweet)
      puts tweet.inspect
      return "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
    end

  end
end
