require 'rest-client'
require 'aws-sdk-s3'
require 'mime-types'

module JekyllPosse
  class MediumPosse

    def initialize(data, content, permalink)
      @domain = "https://api.medium.com"
      @data = data
      @content = content
      @permalink = permalink
      @token = ENV["MEDIUM_BEARER_TOKEN"]
      user = RestClient.get "#{@domain}/v1/me", {:Authorization => "Bearer #{@token}"}
      @user_id = JSON.parse(user)["data"]["id"]
    end

    def posts
      payload = {
        "title" => @data["title"],
        "contentFormat" => "html",
        "content" => @content,
        "canonicalUrl" => @permalink
      }
      tags = get_tags(@data)
      payload["tags"] = tags if tags
      post = RestClient.post "#{@domain}/v1/users/#{@user_id}/posts", payload, {:Authorization => "Bearer #{@token}"}
      JSON.parse(post)["data"]["url"]
    end

    def get_tags(data)
      tags = data.has_key?("categories") ? data["categories"] : nil
    end
  end
end