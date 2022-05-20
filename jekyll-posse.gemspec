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
  s.files         = `git ls-files -z`.split("\x0").grep(%r!^lib/!)
  s.require_paths = ["lib"]
  s.metadata      = {
    "source_code_uri" => "https://github.com/joebuhlig/jekyll-posse",
    "bug_tracker_uri" => "https://github.com/joebuhlig/jekyll-posse/issues",
    "changelog_uri"   => "https://github.com/joebuhlig/jekyll-posse/releases",
    "homepage_uri"    => s.homepage,
  }
  s.add_dependency "jekyll", ">= 3.7", "< 5.0"
  s.add_dependency "kramdown-parser-gfm", ">= 1.1.0"
  s.add_dependency "tweetkit", ">= 0.2.0"
  s.add_dependency "tumblr_client", ">= 0.8.6"
  s.add_dependency "oauth"
  s.add_dependency "aws-sdk-s3"
end

