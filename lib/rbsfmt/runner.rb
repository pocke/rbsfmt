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
        @tokens << raw('class') << [:space_or_newline] << raw(node.name.name.to_s) << indent(INDENT_WIDTH) << [:newline]
        node.members.each do |member|
          format member
        end
        @tokens << [:dedent, INDENT_WIDTH] << raw('end')
      when Ruby::Signature::AST::Members::MethodDefinition
        @tokens << raw('def') << [:space_or_newline] << raw(node.name.to_s) << [:nothing_or_newline] << raw(':') << [:space_or_newline]
        @tokens << indent(4 + node.name.to_s.size)
        node.types.each.with_index do |type, idx|
          format type
          @tokens << [:newline] << raw("|") << [:space_or_newline] unless idx == node.types.size - 1
        end
        @tokens << [:dedent, 4 + node.name.to_s.size]
        @tokens << [:newline]
      when Ruby::Signature::MethodType
        format node.type
      when Ruby::Signature::Types::Function
        @tokens << raw('(')
        # TODO: other args
        node.required_positionals.each.with_index do |arg, idx|
          format arg
          # FIXME: trailing comma with multiline
          @tokens << raw(',') << [:space_or_newline]  unless idx == node.required_positionals.size - 1
        end
        @tokens << raw(")") << [:space_or_newline] << raw('->') << [:space_or_newline]
        format node.return_type
      when Ruby::Signature::Types::Function::Param
        format node.type
        @tokens << [:space_or_newline] << raw(node.name.to_s) if node.name
      when Ruby::Signature::Types::Bases::Base # any, void, etc.
        @tokens << raw(node.to_s)
      when Ruby::Signature::Types::ClassInstance
        @tokens << raw(node.name.to_s)
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
