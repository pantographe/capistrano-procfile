# Reads and writes Procfiles.
#
# A valid Procfile entry is captured by this regex:
#
#   /^([A-Za-z0-9_]+):\s*(.+)$/
#
# All other lines are ignored.
#
# Mainly from: https://github.com/ddollar/foreman/blob/9bb0903fe864bf3f4d663e9c6fb8d6683ecabf34/lib/foreman/procfile.rb
#
module Capistrano
  module Procfile
    class Procfile
      # Initialize a Procfile.
      #
      # @param [String] filename       An optional filename or Procfile content to read from.
      # @param [String] lock_filename  An optional lock_filename or Procfile.lock content to read from.
      def initialize(filename=nil, lock_filename=nil)
        @entries = Hash.new

        load(filename) if filename
        load_lock(lock_filename) if lock_filename
      end

      # Yield each +Procfile+ entry in order.
      #
      # @option [String, Array] names  Key or keys to select.
      #
      # @return [Hash]
      def entries(names: :unknown, &blk)
        if names != :unknown
          entries = @entries.select { |key, _| names.to_a.include?(key) }
        else
          entries = @entries
        end

        if block_given?
          entries.each do |(name, command)|
            yield name, command
          end
        else
          entries
        end
      end

      # Retrieve a +Procfile+ command by name.
      #
      # @param [String, Symbol] name  The name of the Procfile entry to retrieve.
      #
      # @return [String]
      def [](name)
        name = name.to_sym

        @entries[name] if @entries.key? name
      end

      # Create a +Procfile+ entry.
      #
      # @param [String] name     The name of the +Procfile+ entry to create.
      # @param [String] command  The command of the +Procfile+ entry to create.
      #
      def []=(name, command)
        delete name

        @entries.store name, command
      end

      # Remove a +Procfile+ entry.
      #
      # @param [String] name  The name of the +Procfile+ entry to remove.
      #
      def delete(name)
        @entries.delete name
      end

      # Load a Procfile from a file.
      #
      # @param [String] filename  The filename of the +Procfile+ to load.
      def load(filename)
        @entries.replace parse(filename)
      end

      # Save a Procfile to a file.
      #
      # @param [String] filename  Save the +Procfile+ to this file.
      def save(filename)
        File.open(filename, "w") do |file|
          file.puts self.to_s
        end
      end

      def diff(procfile, &block)
        raise Exception, "" unless procfile.kind_of?(Procfile)

        changes       = {}
        # self_keys     = @entries.map { |e| e[0] }
        # procfile_keys = procfile.entries.map { |e| e[0] }

        self_keys     = @entries.to_h.keys
        procfile_keys = procfile.to_h.keys

        # puts self_keys.inspect
        (self_keys - procfile_keys).each do |k|
          changes[k] = :removed
        end

        (procfile_keys - self_keys).each do |k|
          changes[k] = :added
        end

        (self_keys & procfile_keys).each do |k|
          changes[k] = self[k] === procfile[k] ? :unchanged : :updated
        end

        changes
      end

      # Get the +Procfile+ as a +String+.
      #
      # @return [String]
      def to_s
        lines = []

        @entries.each do |name, command|
          lines << [name, command].join(": ")
        end

        lines.join("\n")
      end

      private

      # Parse the +Procfile+.
      #
      # @param [String] procfile  Filename or a Procfile content to parse.
      #
      # @return [Hash]
      def parse(procfile)
        procfile = File.read(procfile) if File.file? procfile

        entries = Hash.new

        procfile.gsub("\r\n", "\n").split("\n").map do |line|
          if line =~ /^([A-Za-z0-9_-]+):\s*(.+)$/
            entries.store($1.to_sym, $2.to_s)
          end
        end

        entries.compact
      end

    end
  end
end
