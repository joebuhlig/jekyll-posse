module Jekyll
  module Commands
    class Syndicate < Jekyll::Command
      def self.init_with_program(prog)
        prog.command(:syndicate) do |c|
          c.syntax "syndicate [options]"
          c.description 'Create a new Jekyll site.'

          c.option 'dest', '-d DEST', 'Where the site should go.'

          c.action do |args, options|
            JekyllPosse.syndicate(args, options)
          end
        end
      end
    end
  end
end
