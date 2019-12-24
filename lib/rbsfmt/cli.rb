module Rbsfmt
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      fname = @argv.first
      Runner.new(File.read(fname)).run
    end
  end
end
