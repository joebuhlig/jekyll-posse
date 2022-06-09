require 'rest-client'

module JekyllPosse
  class MicroBlogPosse

    def initialize()
      @token = ENV["MICROBLOG_APP_TOKEN"]
    end

    def download()
      jekyll_conf = Jekyll.configuration.dup
      posse_conf = jekyll_conf["jekyll_posse"]
      site = Jekyll::Site.new(jekyll_conf)
      site.read
      username = posse_conf["microblog"]
      payload = RestClient.get("https://micro.blog/posts/#{username}", :headers => {"Authorization" => @token})
      microblog_data = {}
      JSON.parse(payload)["items"].each do |post|
        path = URI.parse(post["url"]).path
        microblog_data[path] = post["id"]
      end

      posse_conf["collections"].each do |name|
        collection = Jekyll::Collection.new(site, name)
        collection.read
        if collection.metadata["output"]
          collection.docs.each do |post|
            post.read
            raw = File.read(post.path)
            raw =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
            content = $POSTMATCH
            data = Psych.load(Regexp.last_match(1))
            mb_id = microblog_data[post.url]
            if mb_id
              syndication_url = "https://micro.blog/#{username}/#{mb_id}"
              unless data["syndication"] and data["syndication"].include? syndication_url
                data["syndication"].push(syndication_url)
                puts "Updating: #{post.path}"
                File.write(post.path, "#{Psych.dump(data)}---\n#{post.content}")
              end
            end
          end
        end
      end
    end

  end
end
