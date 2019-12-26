module Rbsfmt
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      parse
      @args.each do |fname|
        $stderr.puts "Formatting #{fname}" if @params[:verbose]
        with_out(fname) do |out|
          Runner.new(File.read(fname), out: out).run
        end
      end
    end

    private def with_out(fname, &block)
      if @params[:write]
        File.open(fname, 'r+') do |f|
          block.call f
        end
      else
        block.call $stdout
      end
    end

    private def parse
      opt = OptionParser.new
      @params = {}
      opt.on('-w', '--write')
      opt.on('--verbose')
      @args = opt.parse(@argv, into: @params)
    end
  end
end
