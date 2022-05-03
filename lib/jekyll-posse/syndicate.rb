require 'jekyll'
require 'fileutils'
require 'psych'
require 'jekyll-posse/twitter'
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
                data["mp-syndicate-to"].each_with_index do |silo, index|
                  data["syndication"] = [] unless data.include?("syndication")
                  if silo.include? "twitter.com"
                    twitter = JekyllPosse::TwitterPosse.new(data,sanitized)
                    response = twitter.send(collection.to_sym)
                    data["syndication"][index] = response
                    data["mp-syndicate-to"].slice!(index)
                  else
                  end
                end
              end

              data.delete("mp-syndicate-to") if (data["mp-syndicate-to"] == [])

              File.write(file, "#{Psych.dump(data)}---\n#{content}")
            end
          end
        end
      end
    end

  end
end
