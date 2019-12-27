module Rbsfmt
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      parse
      @args.each do |fname|
        $stderr.puts "Formatting #{fname}" if @params[:verbose]
        content = File.read(fname)
        buf = StringIO.new
        Runner.new(content, out: buf).run
        if @params[:write]
          File.write(fname, buf.string)
        else
          $stdout.write(buf.string)
        end
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
