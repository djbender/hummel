require "json"

module Huml
  module Encode
    # Regular expression to validate bare keys (no quotes needed)
    BARE_KEY_REGEX = /^[a-zA-Z][a-zA-Z0-9_-]*$/

    class << self
      # Convert a Ruby object to HUML format
      def stringify(obj, cfg = {})
        lines = []
        lines.concat(["%HUML v0.1.0", ""]) if cfg[:include_version]

        to_value(obj, 0, lines, true)
        lines << "" # Ensure document ends with newline

        lines.join("\n")
      end

      private

      # Core encoding methods

      # Encode a value to HUML format
      def to_value(value, indent, lines, is_root_level = false)
        return lines[-1] += "null" if value.nil?

        case value
        when TrueClass, FalseClass
          lines[-1] += value.to_s
        when Numeric
          lines[-1] += format_number(value)
        when String
          to_string(value, indent, lines)
        when Array
          to_array(value, indent, lines, is_root_level)
        when Hash
          to_object(value, indent, lines, is_root_level)
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

      # Encode a string value
      def to_string(str, indent, lines)
        unless str.include?("\n")
          # Single-line string - use JSON for proper escaping
          lines[-1] += str.to_json
          return
        end

        # Multi-line string
        lines[-1] += "```"
        str_lines = str.split("\n")
        str_lines.pop if str_lines.last&.empty? # Remove empty last line if string ends with newline

        str_lines.each { |line| lines << "#{' ' * indent}#{line}" }
        lines << "#{' ' * (indent - 2)}```"
      end

      # Encode an array value
      def to_array(arr, indent, lines, is_root_level = false)
        return lines[-1] += "[]" if arr.empty?

        # For root level arrays, don't add extra indentation
        item_indent = is_root_level ? 0 : indent

        arr.each do |item|
          lines << "#{' ' * item_indent}- "

          if vector?(item)
            lines[-1] += "::"
            to_value(item, item_indent + 2, lines)
          else
            to_value(item, item_indent, lines)
          end
        end
      end

      # Encode an object value
      def to_object(obj, indent, lines, is_root_level = false)
        entries = obj.to_a
        return lines[-1] += "{}" if entries.empty?

        # Sort keys for deterministic output
        entries.sort_by! { |key, _| key.to_s }

        # For root level objects, don't add extra indentation
        key_indent = is_root_level ? 0 : indent

        entries.each do |key, value|
          write_key_value_pair(key, value, key_indent, lines)
        end
      end

      # Writes a key-value pair
      def write_key_value_pair(key, value, indent, lines)
        lines << "#{' ' * indent}#{quote_key(key)}"

        lines[-1] += if vector?(value)
          empty_vector?(value) ? ":: " : "::"
        else
          ": "
        end

        to_value(value, indent + 2, lines)
      end

      # Helper methods

      # Determines if a value is a vector (array or object)
      def vector?(value)
        value.is_a?(Array) || value.is_a?(Hash)
      end

      # Determines if a vector is empty
      def empty_vector?(value)
        (value.is_a?(Array) || value.is_a?(Hash)) && value.empty?
      end

      # Quotes a key if necessary
      def quote_key(key)
        key_str = key.to_s
        BARE_KEY_REGEX.match?(key_str) ? key_str : key_str.to_json
      end
    end
  end
end
