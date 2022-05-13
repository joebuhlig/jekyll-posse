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
      jekyll_conf = Jekyll.configuration.dup
      @posse_conf = jekyll_conf["jekyll_posse"]
      @posse_conf["collections"].each do |collection|
        if jekyll_conf["collections"][collection]["output"]
          Dir["_#{collection}/*.md"].each do |file|
            content = File.read(file)

            if content =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
              content = $POSTMATCH

              match = Regexp.last_match[1] if Regexp.last_match
              data = Psych.load(match)
              data["syndication"] = [] unless data.include?("syndication")

              if data["mp-syndicate-to"] and data["date"] < Time.now
                puts data
                if data["mp-syndicate-to"].kind_of?(Array)
                  data["mp-syndicate-to"].each_with_index do |silo, index|
                    syndication_url = mp_syndicate(collection, data, content, silo)
                    data["syndication"].push(syndication_url)
                    data["mp-syndicate-to"].slice!(index)
                    puts "Syndicated to: #{syndication_url}"
                  end
                else
                  syndication_url = mp_syndicate(collection, data, content, data["mp-syndicate-to"])
                  data["syndication"][0] = syndication_url
                  data["mp-syndicate-to"] = ""
                  puts "Syndicated to: #{syndication_url}"
                end
              end

              data.delete("mp-syndicate-to") if (data["mp-syndicate-to"] == [])
              File.write(file, "#{Psych.dump(data)}---\n#{content}")
            end
          end
        end
      end
    end

    def self.mp_syndicate(collection, data, content, silo)
      puts silo
      service = @posse_conf["mp-syndicate-to"][silo]
      puts service
      rendered = Kramdown::Document.new(content).to_html
      sanitized = Sanitize.fragment(rendered)

      if service["type"] == "twitter"
        puts "Syndicating to Twitter"
        twitter = JekyllPosse::TwitterPosse.new(data,sanitized)
        twitter.send(collection.to_sym)
      elsif service["type"] == "mastodon"
        puts "Syndicating to Mastodon"
        url = service["url"]
        mastodon = JekyllPosse::MastodonPosse.new(data, sanitized, url)
        mastodon.send(collection.to_sym)
      elsif service["type"] == "tumblr"
        puts "Syndicating to Tumblr"
        blog = service["blog"]
        tumblr = JekyllPosse::TumblrPosse.new(data, rendered, blog)
        tumblr.send(collection.to_sym)
      else

      end
    end

  end
end
