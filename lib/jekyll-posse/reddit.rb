require 'rest-client'
require 'aws-sdk-s3'
require 'mime-types'

module JekyllPosse
  class RedditPosse

    def initialize(data = nil, content = nil, sanitized = nil, silo = nil, permalink = false, download = false)
      @domain = "https://oauth.reddit.com/"
      @data = data
      @content = content
      @sanitized = sanitized
      @subreddit = get_subreddit(silo)
      @permalink = permalink
      @download = download
      @token = ENV["REDDIT_BEARER_TOKEN"]
    end

    def posts
      payload = {
        "api_type" => "json",
        "kind" => "link",
        "sr" => @subreddit,
        "url" => @permalink,
        "title" => @data["title"]
      }
      post = RestClient.post "#{@domain}api/submit", payload, {:Authorization => "Bearer #{@token}"}
      format_post(post)
    end

    def notes
      payload = {
        "api_type" => "json",
        "kind" => "self",
        "sr" => @subreddit,
        "text" => @content,
        "title" => create_title
      }
      post = RestClient.post "#{@domain}api/submit", payload, {:Authorization => "Bearer #{@token}"}
      format_post(post)
    end

    def replies
      fullname = get_fullname(@data["in-reply-to"])
      payload = {
        "api_type" => "json",
        "kind" => "self",
        "thing_id" => fullname,
        "text" => @content
      }
      post = RestClient.post "#{@domain}api/comment", payload, {:Authorization => "Bearer #{@token}"}
      download(fullname)
      format_post(post)
    end

    def reposts
    end

    def likes
      fullname = get_fullname(@data["like-of"])
      payload = {
        "api_type" => "json",
        "id" => fullname,
        "dir" => 1
      }
      like = RestClient.post "#{@domain}api/vote", payload, {:Authorization => "Bearer #{@token}"}
      download(fullname)
      @data["like-of"]
    end

    def photos
      content = @content.dup
      @data["photo"].each do |photo|
        media_id = post_media(photo)
        content << "\n\n![img](#{media_id})"
      end
      richtext_data = {
        "output_mode" => "rtjson",
        "markdown_text" => content
      }
      richtext_js = RestClient.post "#{@domain}api/convert_rte_body_format", richtext_data, {:Authorization => "Bearer #{@token}"}
      json = JSON.parse(richtext_js)["output"]
      payload = {
        "api_type" => "json",
        "kind" => "self",
        "sr" => @subreddit,
        "richtext_json" => json.to_json,
        "title" => create_title
      }
      post = RestClient.post "#{@domain}api/submit", payload, {:Authorization => "Bearer #{@token}"}
      format_post(post)
    end

    def videos
      content = @content.dup
      @data["video"].each do |video|
        media_id = post_media(video)
        content << "\n\n![video](#{media_id})"
      end
      richtext_data = {
        "output_mode" => "rtjson",
        "markdown_text" => content
      }
      richtext_js = RestClient.post "#{@domain}api/convert_rte_body_format", richtext_data, {:Authorization => "Bearer #{@token}"}
      json = JSON.parse(richtext_js)["output"]
      payload = {
        "api_type" => "json",
        "kind" => "self",
        "sr" => @subreddit,
        "richtext_json" => json.to_json,
        "title" => create_title
      }
      post = RestClient.post "#{@domain}api/submit", payload, {:Authorization => "Bearer #{@token}"}
      format_post(post)
    end

    def format_post(post)
      data = JSON.parse(post)["json"]["data"]
      if data.has_key? "url"
        return data["url"]
      elsif data.has_key? "things"
        return "https://reddit.com#{data['things'][0]['data']['permalink']}"
      end
    end

    def get_subreddit(silo)
      if silo
        parts = silo.split('/')
        if parts[3] == 'u'
          subreddit = "u_#{parts[4]}"
        else
          subreddit = parts[4]
        end
        subreddit
      else
        nil
      end
    end

    def get_fullname(url)
      uri = url.split('/')
      if uri[8]
        return "t1_#{uri[8]}"
      else
        return "t3_#{uri[6]}"
      end
    end

    def create_title
      @sanitized.split[0...11].join(' ')
    end

    def post_media(path)
      puts "Uploading to Reddit: #{path}"
      file_type = MIME::Types.type_for(path.split('.').last).first.to_s
      payload = {
        "filepath" => path,
        "mimetype" => file_type
      }
      media = RestClient.post "#{@domain}api/media/asset.json", payload, {:Authorization => "Bearer #{@token}"}
      data = JSON.parse(media)
      upload_lease = data["args"]
      upload_url = "https:#{upload_lease['action']}"
      upload_data = {}
      for item in upload_lease["fields"]
        upload_data[item["name"]] = item["value"]
      end
      upload_data["file"] = File.new(path)
      upload = RestClient.post upload_url, upload_data
      data["asset"]["asset_id"]
    end

    def download(item)
      s3 = Aws::S3::Client.new(
        access_key_id: ENV["S3_ACCESS_KEY"],
        secret_access_key: ENV["S3_SECRET_KEY"],
        endpoint: ENV["S3_POSSE_ENDPOINT"],
        region: ENV["S3_POSSE_REGION"]
      )

      if item.start_with?('http')
        fullname = get_fullname(item)
      else
        fullname = item
      end
      payload = {
        "api_type" => "json",
        "id" => fullname
      }
      request = RestClient.get "#{@domain}api/info?id=#{fullname}", {:Authorization => "Bearer #{@token}"}
      data = JSON.parse(request)["data"]

      author_fullname = data["children"][0]["data"]["author_fullname"]
      author_request = RestClient.get "https://www.reddit.com/api/user_data_by_account_ids.json?ids=#{author_fullname}"
      author = JSON.parse(author_request)[author_fullname]
      username = author["name"]
      user_data = RestClient.get "#{@domain}/user/#{username}/about", {:Authorization => "Bearer #{@token}"}
      user_title = JSON.parse(user_data)["data"]["subreddit"]["title"]
      user_name = user_title.empty? ? username : user_title

      data["username"] = username
      data["name"] = user_name
      uri = URI.parse(author["profile_img"])
      uri.query = nil
      avatar_url = uri.to_s
      file_type = MIME::Types.type_for(uri.to_s.split('.').last).first
      ext = file_type.preferred_extension
      data["avatar"] = "avatars/reddit/#{username}.#{ext}"

      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_POSSE_BUCKET"], key: data["avatar"])
      obj.upload_stream(acl: 'public-read', content_type: file_type.to_s) do |write_stream|
        IO.copy_stream(URI.open(avatar_url), write_stream)
      end
      FileUtils.mkdir_p("_data/reddit/") unless File.directory?("_data/reddit/")
      File.open("_data/reddit/#{fullname}.json","w") do |f|
        f.write(data.to_json)
      end
      puts "Reddit post downloaded to: _data/reddit/#{fullname}.json"
    end

  end
end
