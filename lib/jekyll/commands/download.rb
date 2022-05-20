module Jekyll
  module Commands
    class Download < Jekyll::Command
      def self.init_with_program(prog)
        prog.command(:download) do |c|
          c.syntax "syndicate [options]"
          c.description 'Create a new Jekyll site.'

          c.option 'twitter', '--twitter', 'Download from Twitter'

          c.action do |args, options|
            JekyllPosse.download(args, options)
          end
        end
      end
    end
  end
end