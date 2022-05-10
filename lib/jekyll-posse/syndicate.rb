require 'jekyll'
require 'fileutils'
require 'psych'
require 'jekyll-posse/twitter'
require 'jekyll-posse/mastodon'
require 'sanitize'
require 'kramdown'
require 'kramdown-parser-gfm'

module JekyllPosse
  class Syndicate

    def self.process
      JekyllPosse.collections.each do |collection|
        if Jekyll.configuration["collections"][collection]["output"]
          Dir["_#{collection}/*.md"].each do |file|
            content = File.read(file)

            if content =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
              content = $POSTMATCH
              rendered = Kramdown::Document.new(content).to_html
              sanitized = Sanitize.fragment(rendered)

              match = Regexp.last_match[1] if Regexp.last_match
              data = Psych.load(match)

              if data["mp-syndicate-to"] and data["date"] < Time.now

                if data["mp-syndicate-to"].kind_of?(Array)
                  data["mp-syndicate-to"].each_with_index do |silo, index|
                    syndication_url = mp_syndicate(collection, data, sanitized, silo)
                    data["syndication"][index] = syndication_url
                    data["mp-syndicate-to"].slice!(index)
                  end
                else
                  syndication_url = mp_syndicate(collection, data, sanitized, data["mp-syndicate-to"])
                  data["syndication"] = syndication_url
                  data["mp-syndicate-to"] = ""
                end

              end

              data.delete("mp-syndicate-to") if (data["mp-syndicate-to"] == [])
              File.write(file, "#{Psych.dump(data)}---\n#{content}")
            end
          end
        end
      end
    end

    def self.mp_syndicate(collection, data, sanitized, silo)
      service = JekyllPosse.configuration["mp-syndicate-to"][silo]
      data["syndication"] = [] unless data.include?("syndication")

      if service["type"] == "twitter"
        twitter = JekyllPosse::TwitterPosse.new(data,sanitized)
        twitter.send(collection.to_sym)
      elsif service["type"] == "mastodon"
        url = service["url"]
        mastodon = JekyllPosse::MastodonPosse.new(data, sanitized, url)
        mastodon.send(collection.to_sym)
      else

      end
    end

  end
end
