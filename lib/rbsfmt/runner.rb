module Rbsfmt
  class Runner
    INDENT_WIDTH = 2

    def initialize(source, out: $stdout)
      @original_source = source
      @out = out
    end

    def run
      @tokens = []
      @parent_stack = []

      trees = parse
      trees.each do |tree|
        format tree
      end

      @out.write join_tokens @tokens
    end

    private def format(node)
      @parent_stack.push node
      case node
      when Ruby::Signature::AST::Declarations::Class,
           Ruby::Signature::AST::Declarations::Module,
           Ruby::Signature::AST::Declarations::Interface,
           Ruby::Signature::AST::Declarations::Constant,
           Ruby::Signature::AST::Members::MethodDefinition
        preserve_empty_line(node)
      end

      preserve_comments node
      case node
      when Ruby::Signature::AST::Declarations::Class
        @tokens << raw('class') << [:space] << raw(node.name.name.to_s)
        format node.type_params
        @tokens << indent(INDENT_WIDTH) << [:newline]
        node.members.each do |member|
          format member
        end
        @tokens << [:dedent, INDENT_WIDTH] << raw('end') << [:newline]
      when Ruby::Signature::AST::Declarations::Module
        @tokens << raw('module') << [:space] << raw(node.name.name.to_s)
        format node.type_params
        @tokens << indent(INDENT_WIDTH) << [:newline]
        node.members.each do |member|
          format member
        end
        @tokens << [:dedent, INDENT_WIDTH] << raw('end') << [:newline]
      when Ruby::Signature::AST::Declarations::Interface
        @tokens << raw('interface') << [:space] << raw(node.name.name.to_s)
        format node.type_params
        @tokens << indent(INDENT_WIDTH) << [:newline]
        node.members.each do |member|
          format member
        end
        @tokens << [:dedent, INDENT_WIDTH] << raw('end') << [:newline]
      when Ruby::Signature::AST::Declarations::Constant
        @tokens << raw(node.name.to_s) << raw(':') << [:space]
        format node.type
        @tokens << [:newline]
      when Ruby::Signature::AST::Declarations::ModuleTypeParams
        params = node.params
        unless params.empty?
          @tokens << raw('[')
          params.each.with_index do |t, idx|
            @tokens << raw(t.name.to_s)
            @tokens << raw(",") << [:space] unless idx == params.size - 1
          end
          @tokens << raw(']')
        end
      when Ruby::Signature::AST::Members::MethodDefinition
        @tokens << raw('def') << [:space] << raw(node.name.to_s) << raw(':') << [:space]
        @tokens << indent(4 + node.name.to_s.size)
        node.types.each.with_index do |type, idx|
          format type
          @tokens << [:newline] << raw("|") << [:space] unless idx == node.types.size - 1
        end
        @tokens << [:dedent, 4 + node.name.to_s.size]
        @tokens << [:newline]
      when Ruby::Signature::AST::Members::Alias
        @tokens << raw('alias') << [:space] << raw(node.new_name.to_s) << [:space] << raw(node.old_name.to_s) << [:newline]
      when Ruby::Signature::AST::Members::Include
        @tokens << raw('include') << [:space]
        format node.name
        unless node.args.empty?
          @tokens << raw('[')
          node.args.each.with_index do |t, idx|
            format t
            @tokens << raw(',') << [:space] unless idx == node.args.size - 1
          end
          @tokens << raw(']')
        end
        @tokens << [:newline]
      when Ruby::Signature::AST::Members::Private
        @tokens << raw('private') << [:newline]
      when Ruby::Signature::AST::Members::Public
        @tokens << raw('public') << [:newline]
      when Ruby::Signature::TypeName
        @tokens << raw(node.to_s)
      when Ruby::Signature::MethodType
        unless node.type_params.empty?
          @tokens << raw('[')
          node.type_params.each.with_index do |t, idx|
            @tokens << raw(t.to_s)
            @tokens << raw(',') << [:space] unless idx == node.type_params.size - 1
          end
          @tokens << raw(']') << [:space]
        end
        format node.type
        @tokens << [:space]
        if node.block
          format node.block
          @tokens << [:space]
        end
        @tokens << raw('->') << [:space]
        format node.type.return_type
      when Ruby::Signature::MethodType::Block
        @tokens << raw("{") << [:space]
        format node.type
        @tokens << [:space] << raw('->') << [:space]
        format node.type.return_type
        @tokens << [:space] << raw("}")
      when Ruby::Signature::Types::Function
        @tokens << raw('(')
        # FIXME: trailing comma with multiline
        all_params = [*node.required_positionals, *node.optional_positionals, node.rest_positionals, *node.trailing_positionals, *node.required_keywords.map(&:last), *node.optional_keywords.map(&:last), node.rest_keywords].compact
        node.required_positionals.each do |arg|
          format arg
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(arg) } == all_params.size - 1
        end
        node.optional_positionals.each do |arg|
          @tokens << raw('?')
          format arg
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(arg) } == all_params.size - 1
        end
        if node.rest_positionals
          @tokens << raw('*')
          format node.rest_positionals
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(node.rest_positionals) } == all_params.size - 1
        end
        node.trailing_positionals.each do |arg|
          format arg
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(arg) } == all_params.size - 1
        end
        node.required_keywords.each do |name, arg|
          @tokens << raw(name.to_s) << raw(':') << [:space]
          format arg
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(arg) } == all_params.size - 1
        end
        node.optional_keywords.each do |name, arg|
          @tokens << raw('?') << raw(name.to_s) << raw(':') << [:space]
          format arg
          @tokens << raw(',') << [:space]  unless all_params.find_index { |x| x.equal?(arg) } == all_params.size - 1
        end
        if node.rest_keywords
          @tokens << raw('**')
          format node.rest_keywords
        end
        @tokens << raw(")")
      when Ruby::Signature::Types::Function::Param
        format node.type
        @tokens << [:space] << raw(node.name.to_s) if node.name
      when Ruby::Signature::Types::Proc
        @tokens << raw('^')
        format node.type
        @tokens << [:space] << raw('->') << [:space]
        format node.type.return_type
      when Ruby::Signature::Types::Bases::Base, # any, void, etc.
           Ruby::Signature::Types::Variable,
           Ruby::Signature::Types::Interface,
           Ruby::Signature::Types::Literal
        @tokens << raw(node.to_s)
      when Ruby::Signature::Types::ClassInstance
        @tokens << raw(node.name.to_s)
        unless node.args.empty?
          @tokens << raw('[')
          node.args.each.with_index do |args, idx|
            format args
            @tokens << raw(',') << [:space] unless idx == node.args.size - 1
          end
          @tokens << raw(']')
        end
      when Ruby::Signature::Types::Union
        wrap = parent.is_a?(Ruby::Signature::MethodType) && parent.type.return_type.equal?(node)
        @tokens << raw('(') if wrap
        node.types.each.with_index do |type, idx|
          format type
          @tokens << [:space] << raw("|") << [:space] unless idx == node.types.size - 1
        end
        @tokens << raw(')') if wrap
      when Ruby::Signature::Types::Optional
        format node.type
        @tokens << raw('?')
      when Ruby::Signature::Types::Tuple
        if node.types.empty?
          @tokens << raw('[ ]')
        else
          @tokens << raw('[')
          node.types.each.with_index do |t, idx|
            format t
            @tokens << raw(',') << [:space] unless idx == node.types.size - 1
          end
          @tokens << raw(']')
        end
      when Ruby::Signature::Types::ClassSingleton
        @tokens << raw('singleton(')
        format node.name
        @tokens << raw(')')
      else
        raise "Unknown node: #{node.class}"
      end
    ensure
      @parent_stack.pop
    end

    private def preserve_comments(node)
      return unless node.respond_to? :location

      while !@remaining_comments.empty? && @remaining_comments.first[0] < node.location.start_line
        comment = @remaining_comments.shift[1]
        preserve_empty_line comment
        comment.string.each_line do |line|
          @tokens << [:raw, "# #{line.chomp}"] << [:newline]
        end
      end
    end

    private def preserve_empty_line(node)
      line = node.location.start_line - 2
      return if line < 0

      if @buffer.lines[line].strip.empty?
        @tokens << [:newline]
      end
    end

    private def parse
      @buffer = Ruby::Signature::Buffer.new(name: nil, content: @original_source)
      parser = Ruby::Signature::Parser.new(:SIGNATURE, buffer: @buffer, eof_re: nil)
      parser.do_parse.tap do
        @remaining_comments = parser.instance_variable_get(:@comments).to_a
      end
    end

    private def parent
      @parent_stack[-2]
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
        when :space
          res << ' '
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
