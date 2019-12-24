module Rbsfmt
  class Runner
    INDENT_WIDTH = 2

    def initialize(source, out: $stdout)
      @original_source = source
      @out = out
      @indent = 0
    end

    def run
      trees = Ruby::Signature::Parser.parse_signature(@original_source)
      trees.map do |tree|
        format_decl tree
      end.join("\n\n")
    end

    private def format_decl(node)
      case node
      when Ruby::Signature::AST::Declarations::Class
        name = node.name.name
        @out.puts "class #{name}"
        with_indent(INDENT_WIDTH) do
        end
        @out.puts "end"
      else
        raise "Unknown node: #{node.class}"
      end
    end

    private def with_indent(n, &block)
      @indent += n
      block.call
      @indent -= n
    end
  end
end
