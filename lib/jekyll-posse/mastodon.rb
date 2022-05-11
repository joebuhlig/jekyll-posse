require 'rest-client'

module JekyllPosse
  class MastodonPosse

    def initialize(data, content, url)
      @data = data
      content.sub!(/(@\w*)/, '\1@twitter.com')
      @content = content
      @url = url
      @token = ENV["MASTODON_BEARER_TOKEN"]
    end

    def notes
      payload = {"status": @content}
      toot = RestClient.post "#{@url}/api/v1/statuses", payload.to_json, {:content_type => :json, :Authorization => "Bearer #{@token}"}
      puts toot.inspect
      format_toot(toot)
    end

    def replies
      in_reply_to_id = @data["in-reply-to"].split("/").last.to_i
      if @data["photo"]
        media_id = post_media(@data["photo"])
        toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_id, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      elsif @data["video"]
        media_id = post_media(@data["video"])
        toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_id, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      else
        toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      end
      format_toot(toot)
    end

    def reposts
      id = @data["repost-of"].split("/").last.to_i
      toot = RestClient.post "#{@url}/api/v1/statuses/#{id}/reblog", {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_toot(toot)
    end

    def likes
      id = @data["like-of"].split("/").last.to_i
      toot = RestClient.post "#{@url}/api/v1/statuses/#{id}/favourite", {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_toot(toot)
    end

    def photos
      media_id = post_media(@data["photo"])
      toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_toot(toot)
    end

    def videos
      media_id = post_media(@data["video"])
      toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_toot(toot)
    end

    private
    def format_toot(toot)
      return JSON.parse(toot.body)["url"]
    end

    def post_media(media)
      toot = RestClient.post "#{@url}/api/v1/media", {:file => File.new(media)}, {:Authorization => "Bearer #{@token}"}
      JSON.parse(toot.body)["id"]
    end

  end
end
