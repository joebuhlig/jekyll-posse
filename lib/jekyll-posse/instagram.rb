require 'rest-client'
require 'jekyll-offload'

module JekyllPosse
  class InstagramPosse

    def initialize(data = nil, content = nil, download = false)
      @data = data
      @content = content
      @download = download
      @instagram_id = ENV["INSTAGRAM_ACCOUNT_ID"]
      @token = ENV["INSTAGRAM_ACCESS_TOKEN"]
    end

    def notes
    end

    def replies
      reply_to_url = @data["in-reply-to"]
      comment_id = reply_to_url.split('-').last
      message = CGI::escape(@content)
      comment_url = "https://graph.facebook.com/v13.0/#{comment_id}/replies?access_token=#{@token}&message=#{message}"
      comment = RestClient.post(comment_url, :payload => {}, :headers => {})
      id = JSON.parse(comment)["id"]
      split_url = reply_to_url.split("/")
      split_url[5] = "#comment-#{id}"
      split_url.join("/")
    end

    def reposts
    end

    def likes
    end

    def photos
      creation_id = post_media(@data["photo"], "image")
      publish_url = "https://graph.facebook.com/v13.0/#{@instagram_id}/media_publish?creation_id=#{creation_id}&access_token=#{@token}"
      post = RestClient.post(publish_url, :payload => {}, :headers => {})
      id =  JSON.parse(post)["id"]
      format_post(id)
    end

    def videos
      media_ids = post_media(@data["video"], "video")
      toot = RestClient.post "#{@url}/api/v1/statuses", {"status": @content, "media_ids": media_ids}, {content_type: "application/json", :Authorization => "Bearer #{@token}"}
      format_toot(toot)
    end

    def format_post(id)
      media_url = "https://graph.facebook.com/#{id}?access_token=#{@token}&fields=permalink"
      media = RestClient.get(media_url)
      return JSON.parse(media)["permalink"]
    end

    def post_media(media, type)
      media_ids = []
      caption = CGI::escape(@content)
      carousel_param = ""
      carousel_param = "&is_carousel_item=true" if media.length > 1
      media.each do |item|
        JekyllOffload.push_to_s3(item)
        image_url = CGI::escape("https://bhlg-us.nyc3.cdn.digitaloceanspaces.com/square/#{item}")
        media_type = ""
        media_type = "&media_type=VIDEO" if type == "video"
        url = "https://graph.facebook.com/v13.0/#{@instagram_id}/media?caption=#{caption}&#{type}_url=#{image_url}#{carousel_param}&access_token=#{@token}#{media_type}"
        response = RestClient.post(url, :payload => {}, :headers => {})
        id = JSON.parse(response)["id"]
        media_ids.push(id)
      end
      if media.length > 1
        children = CGI::escape(media_ids.join(','))
        carousel_url = "https://graph.facebook.com/v13.0/#{@instagram_id}/media?media_type=CAROUSEL&children=#{children}&caption=#{caption}&access_token=#{@token}"
        carousel = RestClient.post(carousel_url, :payload => {}, :headers => {})
        id = JSON.parse(carousel)["id"]
        id
      end
    end

    def download_comment(url)
      comment_id = url.split("-").last
      comment_url = "https://graph.facebook.com/v13.0/#{comment_id}?access_token=#{@token}&fields=from,hidden,id,media,parent_id,text,timestamp,user,username"
      comment = RestClient.get(comment_url)
      FileUtils.mkdir_p("_data/instagram/comments/") unless File.directory?("_data/instagram/comments/")
      File.open("_data/instagram/comments/#{comment_id}.json","w") do |f|
        f.write(comment)
      end
      puts "Comment downloaded to: _data/instagram/comments/#{comment_id}.json"
    end

  end
end
