require "json"

module Hummel
  module Encode
    # Regular expression to validate bare keys (no quotes needed)
    BARE_KEY_REGEX = /^[a-zA-Z][a-zA-Z0-9_-]*$/

    class << self
      # Convert a Ruby object to HUML format
      def stringify(obj, cfg = {})
        lines = []
        lines.concat(["%HUML v0.1.0", ""]) if cfg[:include_version]

        lines.concat(encode_value(obj, 0, true))
        lines << "" # Ensure document ends with newline

        lines.join("\n")
      end

      private

      # Core encoding methods

      # Encode a value to HUML format - returns array of lines
      def encode_value(value, indent, is_root_level = false)
        return ["null"] if value.nil?

        case value
        when TrueClass, FalseClass
          [value.to_s]
        when Numeric
          [format_number(value)]
        when String
          encode_string(value, indent)
        when Array
          encode_array(value, indent, is_root_level)
        when Hash
          encode_object(value, indent, is_root_level)
        else
          raise ArgumentError, "Unsupported type: #{value.class}"
        end
      end

      # Type-specific encoding methods

      # Format a number for HUML output
      def format_number(num)
        return "nan" if num.respond_to?(:nan?) && num.nan?
        return "inf" if num == Float::INFINITY
        return "-inf" if num == -Float::INFINITY

        num.to_s
      end

      # Encode a string value - returns array of lines
      def encode_string(str, indent)
        return [str.to_json] unless str.include?("\n")

        # Multi-line string
        str_lines = str.split("\n")
        str_lines.pop if str_lines.last && str_lines.last.empty?

        ["```"] + str_lines.map { |line| "#{" " * indent}#{line}" } + ["#{" " * (indent - 2)}```"]
      end

      # Encode an array value - returns array of lines
      def encode_array(arr, indent, is_root_level = false)
        return ["[]"] if arr.empty?

        item_indent = is_root_level ? 0 : indent

        arr.flat_map do |item|
          item_lines = encode_value(item, item_indent + 2)

          if vector?(item) && !item.empty?
            # Non-empty vector: "- ::" on one line, value on next lines
            ["#{" " * item_indent}- ::"] + item_lines
          else
            # Scalar or empty vector: "- value" on same line
            ["#{" " * item_indent}- #{item_lines.first}"] + item_lines[1..]
          end
        end
      end

      # Encode an object value - returns array of lines
      def encode_object(obj, indent, is_root_level = false)
        return ["{}"] if obj.empty?

        key_indent = is_root_level ? 0 : indent

        obj.sort_by { |key, _| key.to_s }.flat_map do |key, value|
          is_vec = vector?(value)
          value_lines = encode_value(value, key_indent + 2)

          if is_vec && !value.empty?
            # Non-empty vector: key:: on one line, value on next lines
            ["#{" " * key_indent}#{quote_key(key)}::"] + value_lines
          else
            # Scalar or empty vector: combine key and value on first line
            separator = is_vec ? ":: " : ": "
            ["#{" " * key_indent}#{quote_key(key)}#{separator}#{value_lines.first}"] + value_lines[1..]
          end
        end
      end

      # Helper methods

      # Determines if a value is a vector (array or object)
      def vector?(value)
        value.is_a?(Array) || value.is_a?(Hash)
      end

      # Quotes a key if necessary
      def quote_key(key)
        key_str = key.to_s
        BARE_KEY_REGEX.match?(key_str) ? key_str : key_str.to_json
      end
    end
  end
end
