require 'twitter'

module JekyllPosse
  class TwitterPosse

    def initialize(data, content, download = false)
      @data = data
      @content = content
      @download = download
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token = ENV["TWITTER_ACCESS_TOKEN"]
        config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
      end
    end

    def notes
      tweet = @client.update(@content)
      format_tweet(tweet)
    end

    def replies
      id = @data["in-reply-to"].split('/').last.to_i
      if @data["photo"]
        tweet = @client.update_with_media(@content, File.new(@data["photo"]), in_reply_to_status_id: id)
      elsif @data["video"]
        tweet = @client.update_with_media(@content, File.new(@data["video"]), in_reply_to_status_id: id)
      else
        tweet = @client.update(@content, in_reply_to_status_id: id)
      end
      url = format_tweet(tweet)
      if @download
        download_tweet(url)
      end
      return url
    end

    def reposts
      tweet = @client.retweet(@data["repost-of"])
      url = format_tweet(tweet[0])
      if @download
        download_tweet(url)
      end
      return url
    end

    def likes
      tweet = @client.favorite(@data["like-of"])
      url = format_tweet(tweet[0])
      if @download
        download_tweet(url)
      end
      return url
    end

    def photos
      tweet = @client.update_with_media(@content, File.new(@data["photo"]))
      format_tweet(tweet)
    end

    def videos
      tweet = @client.update_with_media(@content, File.new(@data["video"]))
      format_tweet(tweet)
    end

    private
    def format_tweet(tweet)
      return tweet.uri.to_s
    end

    def download_tweet(url)
      id = Twitter::Status::Utils.extract_id(url)
      status = twitter.status(id, tweet_mode: 'extended')
      tweet = status.attrs
      File.open("_data/tweets/#{id}.json","w") do |f|
        f.write(tweet.to_json)
      end
      avatar_url = tweet[:user][:profile_image_url_https]
      host = URI.parse(avatar_url).host
      path = URI.parse(avatar_url).path
      URI.open("assets/avatars/twitter/#{tweet[:user][:screen_name]}.jpg", 'wb') do |file|
        file << URI.open("#{avatar_url}").read
      end
      if tweet[:extended_entities]
        tweet[:extended_entities][:media].each do |entity|
          url = entity[:media_url_https].sub("https://", "")
          FileUtils.mkdir_p(File.dirname("assets/twitter/#{url}"))
          URI.open("assets/twitter/#{url}", 'wb') do |file|
            file << URI.open(entity[:media_url_https]).read
          end
        end
      end
    end

  end
end
