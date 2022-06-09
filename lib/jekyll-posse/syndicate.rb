require 'jekyll'
require 'fileutils'
require 'psych'
require 'jekyll-posse/twitter'
require 'jekyll-posse/mastodon'
require 'jekyll-posse/tumblr'
require 'jekyll-posse/instagram'
require 'jekyll-posse/flickr'
require 'jekyll-posse/reddit'
require 'sanitize'
require 'kramdown'
require 'kramdown-parser-gfm'

module JekyllPosse
  class Syndicate
    YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

    def self.process
      @jekyll_conf = Jekyll.configuration.dup
      @posse_conf = @jekyll_conf["jekyll_posse"]
      site = Jekyll::Site.new(@jekyll_conf)
      site.read
      @posse_conf["collections"].each do |name|
        collection = Jekyll::Collection.new(site, name)
        collection.read
        if collection.metadata["output"]
          collection.docs.each do |post|
            post.read
            raw = File.read(post.path)
            raw =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
            content = $POSTMATCH
            data = Psych.load(Regexp.last_match(1))
            if data["mp-syndicate-to"] and data["date"] < Time.now

              download = false
              if @posse_conf.include? "download" and @posse_conf["download"]
                 download = true
              end

              data["syndication"] = [] unless data.include?("syndication")
              begin
                if data["mp-syndicate-to"].kind_of?(Array)
                  to_delete = []
                  data["mp-syndicate-to"].each do |silo|
                    begin
                      syndication_url = mp_syndicate(post, silo, download)
                    rescue => error
                      puts error
                      puts error.backtrace
                      next
                    end
                    if syndication_url
                      data["syndication"].push(syndication_url)
                      to_delete.push(silo)
                      puts "Syndicated: #{syndication_url}"
                    else
                      puts "FAILED TO SYNDICATE: #{silo}"
                    end
                  end
                  data["mp-syndicate-to"].delete_if { |item| to_delete.include? item }
                else
                  silo = data["mp-syndicate-to"]
                  syndication_url = mp_syndicate(post, silo, download)
                  if syndication_url
                    data["syndication"][0] = syndication_url
                    data["mp-syndicate-to"] = ""
                    puts "Syndicated: #{syndication_url}"
                  else
                    puts "FAILED TO SYNDICATE: #{silo}"
                  end
                end
              rescue => error
                puts error
                puts error.backtrace
              ensure
                data.delete("mp-syndicate-to") if (data["mp-syndicate-to"] == [])
                File.write(post.path, "#{Psych.dump(data)}---\n#{post.content}")
              end
            end

            if data["repost-of"] and !data["syndication"] and !data["mp-syndicate-to"]
              uri = URI.parse(data["repost-of"])
              unless File.file?("_data/websites/#{uri.hostname}#{uri.path}data.json")
                website = JekyllPosse::WebsitePosse.new()
                website.download(data["repost-of"])
              end
            end
          end
        end
      end
    end

    def self.mp_syndicate(post, silo, download)
      service = get_service(silo)
      puts "Syndicating to #{silo}"

      content = post.content
      if @posse_conf["permashortlink"]
        domain = @posse_conf["permashortlink"]["domain"]
        content = insert_shortlink(post, domain)
      end
      rendered = Kramdown::Document.new(content).to_html
      sanitized = Sanitize.fragment(rendered)

      if service == "twitter"
        twitter = JekyllPosse::TwitterPosse.new(post.data, sanitized, download)
        url = twitter.send(post.type.to_sym)
      elsif service == "mastodon"
        url = @posse_conf["mp-syndicate-to"][silo]["url"]
        mastodon = JekyllPosse::MastodonPosse.new(post.data, sanitized, url, download)
        url = mastodon.send(post.type.to_sym)
      elsif service == "tumblr"
        blog = @posse_conf["mp-syndicate-to"][silo]["blog"]
        tumblr = JekyllPosse::TumblrPosse.new(post.data, rendered, blog, download)
        url = tumblr.send(post.type.to_sym)
      elsif service == "instagram"
        instagram = JekyllPosse::InstagramPosse.new(post.data, sanitized, download)
        url = instagram.send(post.type.to_sym)
      elsif service == "flickr"
        flickr = JekyllPosse::FlickrPosse.new(post.data, sanitized, silo, download)
        url = flickr.send(post.type.to_sym)
      elsif service == "reddit"
        reddit = JekyllPosse::RedditPosse.new(post.data, content, sanitized, silo, download)
        url = reddit.send(post.type.to_sym)
      end
      url
    end

    def self.get_service(silo)
      if silo.include? "twitter.com"
        "twitter"
      elsif silo.include? "tumblr.com"
        "tumblr"
      elsif silo.include? "instagram.com"
        "instagram"
      elsif silo.include? "flickr.com"
        "flickr"
      elsif silo.include? "reddit.com"
        "reddit"
      elsif silo.include? "medium.com"
        "medium"
      elsif @posse_conf["mp-syndicate-to"].has_key? silo
        @posse_conf["mp-syndicate-to"][silo]["type"]
      end
    end

    def self.insert_shortlink(post, domain)
      template = @jekyll_conf["jekyll_shorten"][post.type.to_s]["permashortlink"]
      shortlink = Jekyll::URL.new(
        :template => template,
        :placeholders => post.url_placeholders
      )
      lines = post.content.split("\n\n")
      lines.to_enum.with_index.reverse_each do |line, index|
        unless line.match?(/(^<http.*>$|^\[.*\]\(http.*\)$)/)
          lines[index] = line + " (#{domain} #{shortlink})"
          break
        end
      end
      lines.join("\n\n")
    end

  end
end
