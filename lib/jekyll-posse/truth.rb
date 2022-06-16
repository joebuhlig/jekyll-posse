require 'rest-client'

module JekyllPosse
  class TruthPosse

    def initialize(data, content, download = false)
      @data = data
      content.sub!(/(@\w*)/, '\1@twitter.com')
      @content = content
      @url = "https://truthsocial.com"
      @download = download
      @token = ENV["TRUTH_BEARER_TOKEN"]
    end

    def notes
      payload = {"status": @content}
      truth = RestClient.post "#{@url}/api/v1/statuses", payload.to_json, {:content_type => :json, :Authorization => "Bearer #{@token}"}
      format_truth(truth)
    end

    def replies
      in_reply_to_id = @data["in-reply-to"].split("/").last.to_i
      if @data["photo"]
        media_ids = post_media(@data["photo"])
        truth = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_ids, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      elsif @data["video"]
        media_ids = post_media(@data["video"])
        truth = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_ids, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      else
        truth = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "in_reply_to_id": in_reply_to_id}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      end
      format_truth(truth)
    end

    def reposts
      id = @data["repost-of"].split("/").last.to_i
      truth = RestClient.post "#{@url}/api/v1/statuses/#{id}/reblog", {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_truth(truth)
    end

    def likes
      id = @data["like-of"].split("/").last.to_i
      truth = RestClient.post "#{@url}/api/v1/statuses/#{id}/favourite", {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_truth(truth)
    end

    def photos
      media_ids = post_media(@data["photo"])
      truth = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_ids}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_truth(truth)
    end

    def videos
      media_ids = post_media(@data["video"])
      truth = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_ids}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_truth(truth)
    end

    private
    def format_truth(truth)
      return JSON.parse(truth.body)["url"]
    end

    def post_media(media)
      media_ids = []
      media.each do |media_file|
        truth = RestClient.post "#{@url}/api/v1/media", {:file => File.new(media_file)}, {:Authorization => "Bearer #{@token}"}
        media_ids.push(JSON.parse(truth.body)["id"])
      end
      media_ids
    end

  end
end
