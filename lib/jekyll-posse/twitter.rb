require 'twitter'
require 'aws-sdk-s3'
require 'open-uri'
require 'mime-types'

module JekyllPosse
  class TwitterPosse

    def initialize(data = nil, content = nil, download = false)
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
        media = create_media_files(@data["photo"])
        tweet = @client.update_with_media(@content, media, in_reply_to_status_id: id)
      elsif @data["video"]
        media = create_media_files(@data["video"])
        tweet = @client.update_with_media(@content, media, in_reply_to_status_id: id)
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
        download_tweet(@data["repost-of"])
      end
      return url
    end

    def likes
      tweet = @client.favorite(@data["like-of"])
      url = format_tweet(tweet[0])
      if @download
        download_tweet(@data["like-of"])
      end
      return url
    end

    def photos
      media = create_media_files(@data["photo"])
      tweet = @client.update_with_media(@content, media)
      format_tweet(tweet)
    end

    def videos
      media = create_media_files(@data["video"])
      tweet = @client.update_with_media(@content, media)
      format_tweet(tweet)
    end

    def create_media_files(media)
      files = []
      media.each do |media_file|
        files.push(File.new(media_file))
      end
      files
    end

    def format_tweet(tweet)
      return tweet.uri.to_s
    end

    def download_tweet(url)
      s3 = Aws::S3::Client.new(
        access_key_id: ENV["S3_ACCESS_KEY"],
        secret_access_key: ENV["S3_SECRET_KEY"],
        endpoint: ENV["S3_POSSE_ENDPOINT"],
        region: ENV["S3_POSSE_REGION"]
      )

      id = url.split('/').last.to_i
      status = @client.status(id, tweet_mode: 'extended')
      tweet = status.attrs

      avatar_url = tweet[:user][:profile_image_url_https].sub('_normal','_200x200')
      host = URI.parse(avatar_url).host
      path = URI.parse(avatar_url).path

      file_type = MIME::Types.type_for(avatar_url.split('.').last).first
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_POSSE_BUCKET"], key: "avatars/twitter/#{tweet[:user][:screen_name]}.jpg")
      obj.upload_stream(acl: 'public-read', content_type: file_type.to_s) do |write_stream|
        IO.copy_stream(URI.open(avatar_url), write_stream)
      end
      tweet[:avatar] = "avatars/twitter/#{tweet[:user][:screen_name]}.jpg"
      if tweet[:extended_entities]
        tweet[:extended_entities][:media].each do |entity|
          puts entity
          if entity[:type] == "video"
            tweet[:video] = [] unless tweet.include? :video
            variant = entity[:video_info][:variants].sort_by{ |variant| variant[:bitrate].to_i }.reverse[0]
            url = variant[:url].split("?")[0].split("#")[0]
            path = url.sub("https://","")
            tweet[:video].push("media/twitter/#{path}")
          else
            tweet[:photo] = [] unless tweet.include? :photo
            url = entity[:media_url_https]
            path = url.sub("https://","")
            tweet[:photo].push("media/twitter/#{path}")
          end
          file_type = MIME::Types.type_for(url.split('.').last).first
          obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_POSSE_BUCKET"], key: "media/twitter/#{path}")
          obj.upload_stream(acl: 'public-read', content_type: file_type.to_s) do |write_stream|
            IO.copy_stream(URI.open(url), write_stream)
          end
        end
      end
      File.open("_data/tweets/#{id}.json","w") do |f|
        f.write(tweet.to_json)
      end
      puts "Tweet downloaded to: _data/tweets/#{id}.json"
    end

  end
end
