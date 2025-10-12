require "byebug"

module NoNegativeIndex
  refine Array do
    def [](*args)
      first_arg = args.first
      if first_arg.is_a?(Integer) && first_arg < 0
        raise ArgumentError, "Negative indices are not allowed: #{first_arg}"
      end
      super
    end
  end

  refine String do
    def [](*args)
      first_arg = args.first
      if first_arg.is_a?(Integer) && first_arg < 0
        raise ArgumentError, "Negative indices are not allowed: #{first_arg}"
      end
      super
    end
  end
end

module Huml
  module Decode
    def self.parse(input)
      parser = Parser.new(input)
      parser.parse
    end

    class Error < StandardError; end
  end

  class Parser
    using NoNegativeIndex

    class ParseError < StandardError; end

    TYPES = {
      INLINE_DICT: 1,
      MULTILINE_DICT: 2,
      EMPTY_LIST: 3,
      EMPTY_DICT: 4,
      MULTILINE_LIST: 5,
      INLINE_LIST: 6,
      SCALAR: 7
    }
    SPECIAL_VALUES = [
      ["true", true],
      ["false", false],
      ["null", nil]
      # maybe nan, inf?
    ]

    ESCAPE_MAP = {
      '"': '"',
      # '\': '\\',
      '/': '/' # rubocop:disable Style/StringLiterals, Style/QuotedSymbols
      # n: '\n',
      # t: '\t',
      # r: '\r',
      # f: '\f',
      # v: '\v'
    }

    # rubocop:disable Style/StringLiterals
    NUMBER_BASE_PREFIXES = [
      ['0x', 16],
      ['0o', 8],
      ['0b', 2]
    ]
    # rubocop:enable Style/StringLiterals

    attr_reader :data, :pos, :line

    def initialize(data)
      @data = data
      @pos = 0
      @line = 1
    end

    def pos=(value)
      # puts "updating @pos: #{value} from #{caller(1..1).first}"
      @pos = value
    end

    def parse
      skip_blank_lines
      type_handlers = {
        TYPES.fetch(:INLINE_DICT) => -> {
          assert_root_end(parse_inline_vector_contents(TYPES[:INLINE_DICT]), "root inline dict")
        },
        TYPES[:MULTILINE_DICT] => -> {
          parse_multiline_dict(0)
        },
        TYPES[:SCALAR] => -> {
          val = parse_value(0)
          consume_line
          assert_root_end(val, "root scalar value")
        }
      }
      type_handlers[root_type].call
    end

    # 90% sure this is a valid ruby version
    def root_type
      if key_value_pair?
        return TYPES.fetch(:INLINE_DICT) if inline_dict_at_root?
        return TYPES.fetch(:MULTILINE_DICT)
      end
      return TYPES.fetch(:EMPTY_LIST) if peek_string("[]")
      return TYPES.fetch(:EMPTY_DICT) if peek_string("{}")
      return TYPES.fetch(:MULTILINE_LIST) if peek_char(pos) == "-"
      return TYPES.fetch(:INLINE_LIST) if inline_list_at_root?

      TYPES.fetch(:SCALAR)
    end

    def assert_root_end(val, description)
      throw IncompleteMethod.new(__method__)
    end

    def parse_multiline_dict(indent)
      result = {}

      loop do
        skip_blank_lines
        break if done?
        break if current_indent < indent

        if current_indent != indent
          raise ParseError.new("bad indent #{current_indent}, expected #{indent}")
        end

        unless key_start?
          raise ParseError.new("invalid character '#{data[pos]}', expected key")
        end

        key = parse_key

        if result.include?(key)
          raise ParseError.new("duplicat key '#{key}' in dict")
        end

        indicator = parse_indicator

        result[key] = if indicator == ":"
          assert_space("after ':'")

          multiline = peek_string("```") || peek_string('""""')

          value = parse_value(current_indent)

          consume_line unless multiline
          value
        else
          parse_vector(current_indent + 2)
        end
      end

      result
    end

    def parse_multiline_list(indent)
      throw IncompleteMethod.new(__method__)
    end

    def multiline_vector_type(indent)
      skip_blank_lines

      if done? || current_indent < indent
        raise ParseError.new("ambiguous empty vector after '::'. Use [] or {}.")
      end

      if data[pos] == "-"
        "list"
      else
        "dict"
      end
    end

    def parse_vector(indent)
      starting_pos = pos
      skip_spaces

      if done? || data[pos] == "\n" || data[pos] == "#"
        self.pos = starting_pos
        consume_line

        vector_type = multiline_vector_type(indent)
        next_indent = current_indent

        parse_multiline_method = method(:"parse_multiline_#{vector_type}")
        return parse_multiline_method.call(next_indent)
      end

      self.pos = starting_pos
      assert_space("after '::'")

      parse_inline_vector
    end

    def parse_inline_vector
      if peek_string("[]")
        advance(2)
        consume_line
        []
      elsif peek_string("{}")
        advance(2)
        consume_line
        {}
      elsif inline_dict?
        parse_inline_vector_contents(TYPES.fetch(:INLINE_DICT))
      else
        parse_inline_vector_contents(TYPES.fetch(:INLINE_LIST))
      end
    end

    def parse_inline_vector_contents(type)
      result = if type == TYPES.fetch(:INLINE_DICT)
        {}
      else
        []
      end

      while !done? && data[pos] != "\n" && data[pos] != "#"
        skip_first do
          expect_comma
        end

        if type == TYPES(:INLINE_DICT)
          key = parse_key
          if done? || data[pos] != ":"
            raise ParseError.new("expected ':' in inline dict")
          end

          advance(1)
          assert_space("in inline dict")

          if result.inlude?(key)
            raise ParseError("duplicate key '#{key}' in dict")
          end

          result[key] = parse_value(0)
        else
          result.push(parse_value(0))
        end

        if !done? && data[pos] == " "
          next_pos = pos + 1

          next_pos += 1 while next_pos < data.length && data[next_pos] == " "
          if next_pos < data.length && data[next_pos] == ","
            skip_spaces
          else
            break
          end
        end
      end

      consume_line
      result
    end

    def parse_key
      skip_spaces
      if peek_char(pos) == '"'
        return parse_string
      end

      start = pos
      while !done? && alpha_numeric?(data[pos]) ||
          data[pos] == "-" || data[pos] == "_"
        self.pos += 1
      end

      if self.pos == start
        raise ParseError.new("expected a key")
      end

      data[start...self.pos]
    end

    def parse_indicator
      if done? || data[pos] != ":"
        raise ParseError.new("expected ':' or '::' after key")
      end

      advance(1)

      if !done? && data[pos] == ":"
        advance(1)
        return "::"
      end

      ":"
    end

    def parse_value(key_indent)
      if done?
        raise ParseError.new("unexpected end of input, expected a value")
      end
      character = data[self.pos]

      if character == '"'
        return peek_string('"""') ? parse_multiline_string(key_indent, false) : parse_string
      end

      if character == "`" && peek_string("```")
        return parse_multiline_string(key_indent, true)
      end

      SPECIAL_VALUES.each do |string, value|
        if peek_string(string)
          advance(string.length)
          return value
        end
      end

      if character == "+"
        advance(1)
        # TODO: need to figure out infitnity
        # if peek_string('inf')
        #   advance(3)
        #   return Infinity
        # end

        if digit?(peek_char(self.pos))
          self.pos -= 1
          return parse_number
        end
        raise ParseError.new("invalid character after '+'")
      end

      if character == "-"
        advance(1)
        # TODO: figure out infinity
        if peek_string("inf")
          advance(3)
          return -Infinity
        end

        if digit?(peek_char(self.pos))
          self.pos -= 1
          return parse_number
        end

        raise ParseError.new("invalid character after '-'")
      end

      if digit?(character)
        return parse_number
      end

      raise ParseError.new("unexpected chracter #{character} when parsing value")
    end

    def parse_string
      advance(1)

      result = ''
      until done?
        character = data[pos]

        case character
        when '"'
          advance(1)
          return result
        when "\n"
          raise ParseError.new("newlines not allowed in single-line strings")
        when "\\"
          advance(1)
          if done?
            raise ParseError.new("incomplete escape sequence")
          end

          escape = data[pos]

          if ESCAPE_MAP.include?(escape)
            result << ESCAPE_MAP.fetch(escape)
          else
            raise ParseError.new("invalid escape character '\\#{escape}'")
          end
        else
          result << character
        end

        advance(1)
      end

      raise ParseError.new("unclosed string")
    end

    def parse_multiline_string(key_indent, preserve_spaces)
      throw IncompleteMethod.new(__method__)
    end

    # parses numbers in various formats: decimal, hex, octal, binary, float
    def parse_number
      starting_pos = pos

      # handle sign
      next_character = peek_char(pos)
      if ["+", "-"].include?(next_character)
        advance(1)
      end

      NUMBER_BASE_PREFIXES.each do |prefix, base|
        if peek_string(prefix)
          parse_base(starting_pos, base, prefix)
        end
      end

      float = false

      until done?
        character = data[pos]

        if digit?(character) || character == "_"
          advance(1) # TODO: make advance always do 1 by default
        elsif character == "."
          float = true
          advance(1)
        elsif character.downcase == "e"
          float = true
          advance(1)

          if ["+", "-"].include?(peek_char(pos))
            advance(1)
          end
        else
          break
        end
      end

      # remove underscores and parse
      number_string = data[starting_pos...pos].delete("_")
      float ? Float(number_string) : Integer(number_string)
    end

    def parse_base
      throw IncompleteMethod.new(__method__)
    end

    def skip_blank_lines
      until done?
        line_start = self.pos
        skip_spaces

        if done?
          raise ParseError.new("trailing spaces are not allowed") if self.pos > line_start
          return
        end

        if !["\n", "#"].include?(data[self.pos])
          return # Found content
        end

        if data[self.pos] == "\n" && self.pos > line_start
          raise ParseError.new("trailing spaces are not allowed")
        end

        self.pos = line_start
        consume_line
      end
    end

    def consume_line
      content_start = self.pos
      skip_spaces

      if done? || data[self.pos] == "\n"
        if self.pos > content_start
          raise ParseError.new("trailing spaces are not allowed")
        end
      elsif data[self.pos] == "#"
        if self.pos == content_start && current_indent != self.pos - line_start
          raise ParseError.new("a value must be separated from an inline comment by a space")
        end

        self.pos += 1
        if !done? && ![" ", "\n"].include?(data[self.pos])
          raise ParseError.new("comment hash '#' must be followed by a space")
        end

      else
        raise ParseError.new("unexpected content at end of line")
      end

      # NOTE: this section has been refactored
      next_new_line = data.index("\n", self.pos)
      if next_new_line
        remaining_line = data[self.pos...next_new_line]
        if remaining_line.end_with?(" ") && remaining_line.length > 0
          raise ParseError.new("trailing spaces are not allowed")
        end

        self.pos = next_new_line + 1
        @line += 1
      else
        self.pos = data.length
      end
    end

    def consume_line_content
      throw IncompleteMethod.new(__method__)
    end

    def assert_space(context)
      if done? || data[pos] != " "
        raise ParseError.new("expected single space #{context}")
      end

      advance(1)

      if !done? && data[pos] == " "
        raise ParseError("expected signle space #{context}, found multiple")
      end
    end

    def expect_comma
      throw IncompleteMethod.new(__method__)
    end

    def current_indent
      start = line_start
      indent = 0
      while start + indent < data.length && data[start + indent] == " "
        indent += 1
      end

      indent
    end

    def line_start
      if 0 < self.pos && self.pos <= data.length && data[self.pos - 1] == "\n" # rubocop:disable Style/YodaCondition
        self.pos
      else
        return 0 if self.pos <= 0 # prevent -1 array access wrap arounds

        last_newline = data.rindex("\n", self.pos - 1)
        last_newline ? last_newline + 1 : 0
      end
    end

    def key_value_pair?
      current_pos = self.pos
      parse_key
      !done? && data[self.pos] == ":"
    rescue ParseError
      false
    ensure
      self.pos = current_pos
    end

    def inline_dict?
      current_pos = pos
      while current_pos < data.length && ["\n", "#"].include?(data[current_pos])
        if data[current_pos] == ":"
          if current_pos + 1 >= data.length || data[current_pos + 1] != ":"
            return true
          end
        end
        current_pos += 1
      end
      false
    end

    def inline_list_at_root?
      line = data[self.pos...data.index("\n", self.pos)]
      comment_index = line.index("#")
      content = (comment_index >= 0) ? line[0...comment_index] : line

      content.include?(",") && !content.include?(":")
    end

    def inline_dict_at_root?
      line_end = data.index("\n", pos) || data.length
      comment_index = data.index("#", pos) || data.length

      marker = [
        line_end,
        comment_index
      ].min

      line = data[pos...marker]
      has_colon = line.include?(":") && !line.include?("::")
      has_comma = line.include?(",")

      return false unless has_colon && has_comma

      remaining_content = if line_end != -1
        data[0...line_end]
      else
        data
      end.split("\n")[1..].any? do |line|
        trimmed = line.strip
        trimmed && !trimmed.start_with?("#")
      end

      !remaining_content
    end

    def key_start?
      !done? && data[pos] == '"' || alpha?(data[pos])
    end

    def done?
      self.pos >= data.length
    end

    def advance(amount)
      self.pos += amount
    end

    def skip_spaces
      while !done? && data[self.pos] == " "
        advance(1)
      end
    end

    def peek_string(string)
      # really unsure if the start_with? is correct
      self.pos + string.length <= data.length && data[self.pos..].start_with?(string)
    end

    def peek_char(position)
      return data[position] if position >= 0 && position < data.length
      '\0'
    end

    def digit?(character)
      character.match?(/\d/)
    end

    def alpha?(character)
      character.match?(/[a-zA-Z]/)
    end

    def alpha_numeric?(character)
      alpha?(character) || digit?(character)
    end

    def hex?(character)
      throw IncompleteMethod.new(__method__)
    end

    def space_string(string)
      throw IncompleteMethod.new(__method__)
    end

    def error(message)
      throw IncompleteMethod.new(__method__)
    end

    def skip_first
      return unless block_given?

      @first = true if @first.nil?
      yield unless @first
      @first = false
    end

    class IncompleteMethod < StandardError; end
  end
end
