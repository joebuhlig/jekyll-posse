require 'jekyll'
require 'jekyll-posse/syndicate'
require 'jekyll-posse/download'

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

  def self.download(args, options)
    JekyllPosse::Download.process(args, options)
  end
end

require File.expand_path("jekyll/commands/syndicate.rb", __dir__)
require File.expand_path("jekyll/commands/download.rb", __dir__)