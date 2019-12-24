module Rbsfmt
  class Runner
    INDENT_WIDTH = 2

    def initialize(source, out: $stdout)
      @original_source = source
      @out = out
    end

    def run
      @tokens = []

      trees = Ruby::Signature::Parser.parse_signature(@original_source)
      trees.each do |tree|
        format tree
      end
      @tokens << [:newline] # EOF

      @out.write join_tokens @tokens
    end

    private def format(node)
      case node
      when Ruby::Signature::AST::Declarations::Class
        @tokens << raw('class') << [:space_or_newline] << raw(node.name.name.to_s) << indent(INDENT_WIDTH)
        node.members.each do |member|
          format member
        end
        @tokens << [:dedent, INDENT_WIDTH] << raw('end')
      when Ruby::Signature::AST::Members::MethodDefinition
        @tokens << raw('def') << [:space_or_newline] << raw(node.name.to_s) << [:nothing_or_newline] << raw(':') << [:space_or_newline] << raw('(')
        # TODO: args
        @tokens << raw(")") << [:space_or_newline] << raw('->') << [:space_or_newline] << raw('void') << [:newline]
      else
        raise "Unknown node: #{node.class}"
      end
    end

    private def join_tokens(tokens)
      res = +""
      indent = 0
      do_indent = false

      tokens.each do |tok|
        case tok.first
        when :raw
          res << (" " * indent) if do_indent
          do_indent = false
          res << tok[1]
        when :newline
          res << "\n"
          do_indent = true
        when :space_or_newline
          res << ' '
        when :nothing_or_newline
          # TODO
        when :indent
          indent += tok[1]
          res << "\n"
          do_indent = true
        when :dedent
          indent -= tok[1]
        else
          raise "unknown token: #{tok}"
        end
      end

      res
    end

    # --- token helpers

    private def raw(tok)
      [:raw, tok]
    end

    private def indent(width)
      [:indent, width]
    end
  end
end
