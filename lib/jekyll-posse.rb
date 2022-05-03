require 'jekyll'
require 'jekyll-posse/syndicate'

def require_all(path)
  glob = File.join(__dir__, path, "*.rb")
  Dir[glob].sort.each do |f|
    require f
  end
end

module JekyllPosse
  def self.syndicate(args, options)
    JekyllPosse::Syndicate.process
  end

  def self.configuration
    Jekyll.configuration["jekyll_posse"]
  end

  def self.collections
    configuration["collections"]
  end

end

require File.expand_path("jekyll/commands/syndicate.rb", __dir__)
