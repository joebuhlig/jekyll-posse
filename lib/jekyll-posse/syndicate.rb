require 'jekyll'
require 'fileutils'
require 'psych'
require 'jekyll-posse/twitter'
require 'jekyll-posse/mastodon'
require 'jekyll-posse/tumblr'
require 'sanitize'
require 'kramdown'
require 'kramdown-parser-gfm'

module JekyllPosse
  class Syndicate

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
            data = post.data
            data["syndication"] = [] unless data.include?("syndication")
            if data["mp-syndicate-to"] and data["date"] < Time.now
              if data["mp-syndicate-to"].kind_of?(Array)
                data["mp-syndicate-to"].each do |silo|
                  syndication_url = mp_syndicate(post, silo)
                  data["syndication"].push(syndication_url)
                  data["mp-syndicate-to"].delete(silo)
                  puts "Syndicated: #{syndication_url}"
                end
              else
                silo = data["mp-syndicate-to"]
                syndication_url = mp_syndicate(post, silo)
                data["syndication"][0] = syndication_url
                data["mp-syndicate-to"] = ""
                puts "Syndicated: #{syndication_url}"
              end
              data.delete("mp-syndicate-to") if (data["mp-syndicate-to"] == [])
              File.write(post.path, "#{Psych.dump(data)}---\n#{post.content}")
            end

          end
        end
      end
    end

    def self.mp_syndicate(post, silo)
      service = @posse_conf["mp-syndicate-to"][silo]
      puts "Syndicating to #{silo}"

      if @posse_conf["permashortlink"]
        domain = @posse_conf["permashortlink"]["domain"]
        content = insert_shortlink(post, domain)
      end
      rendered = Kramdown::Document.new(content).to_html
      sanitized = Sanitize.fragment(rendered)

      if service["type"] == "twitter"
        twitter = JekyllPosse::TwitterPosse.new(data,sanitized)
        twitter.send(collection.to_sym)
      elsif service["type"] == "mastodon"
        url = service["url"]
        mastodon = JekyllPosse::MastodonPosse.new(data, sanitized, url)
        mastodon.send(collection.to_sym)
      elsif service["type"] == "tumblr"
        blog = service["blog"]
        tumblr = JekyllPosse::TumblrPosse.new(data, rendered, blog)
        tumblr.send(collection.to_sym)
      else

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
          lines[index] = line + " (<#{domain}#{shortlink}>)"
          break
        end
      end
      lines.join("\n\n")
    end

  end
end
