def require_all(path)
  glob = File.join(__dir__, path, "*.rb")
  Dir[glob].sort.each do |f|
    require f
  end
end

module JekyllPosse
  def test
    puts "JekyllPosse.test"
  end
end

require File.expand_path("jekyll/commands/syndicate.rb", __dir__)
