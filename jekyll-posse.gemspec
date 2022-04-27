require "English"
require_relative "lib/jekyll-posse/version"

Gem::Specification.new do |s|
  s.name          = "jekyll-posse"
  s.version       = JekyllPosse::VERSION
  s.license       = "GPL-3.0"
  s.authors       = ["Joe Buhlig"]
  s.email         = ["joe@joebuhlig.com"]
  s.homepage      = "https://rubygems.org/gems/jekyll-posse"
  s.summary       = "A methodology and rake task for syndicating IndieWeb posts from Jekyll."
  s.description   = "A methodology and rake task for syndicating IndieWeb posts from Jekyll."

  s.files         = Dir['lib/*.rb'] + Dir['lib/**/*.rb'] + Dir['lib/**/**/*.rb']
  s.require_paths = ["lib"]
  s.metadata      = {
    "source_code_uri" => "https://github.com/joebuhlig/jekyll-posse",
    "bug_tracker_uri" => "https://github.com/joebuhlig/jekyll-posse/issues",
    "changelog_uri"   => "https://github.com/joebuhlig/jekyll-posse/releases",
    "homepage_uri"    => s.homepage,
  }
  s.add_dependency "jekyll", ">= 3.7", "< 5.0"
end

