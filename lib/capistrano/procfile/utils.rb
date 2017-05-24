require "ostruct"

module Capistrano
  module Procfile
    class Utils
      # From: https://github.com/rails/rails/blob/f90a08c193d4ec8267f4409b7a670c2b53e0621d/activesupport/lib/active_support/inflector/transliterate.rb#L83
      def self.parameterize(string)
        # parameterized_string = transliterate(string)
        parameterized_string = string
        separator = "-"

        # Turn unwanted chars into the separator.
        parameterized_string.gsub!(/[^a-z0-9\-_]+/i, separator)

        unless separator.nil? || separator.empty?
          if separator == "-".freeze
            re_duplicate_separator        = /-{2,}/
            re_leading_trailing_separator = /^-|-$/i
          else
            re_sep = Regexp.escape(separator)
            re_duplicate_separator        = /#{re_sep}{2,}/
            re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/i
          end
          # No more than one of the separator in a row.
          parameterized_string.gsub!(re_duplicate_separator, separator)
          # Remove leading/trailing separator.
          parameterized_string.gsub!(re_leading_trailing_separator, "".freeze)
        end

        parameterized_string.downcase!
        parameterized_string
      end
    end
  end
end
