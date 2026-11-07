# frozen_string_literal: true

require "shellwords"
require "uri"

module PikaBackup
  # The small value types the setup wizard pages pass between each other.
  #
  # Ported from pika-backup/src/widget/dialog/setup/types.rs. That file also
  # defines `ArchiveParams`, built from a `borg::ListArchive` to carry
  # transfer-settings data (a parsed command line, borg stats, a fake
  # history entry) into the "add existing" wizard branch. None of
  # `borg::ListArchive`, `borg::json::Stats` or `borg::invert_command` is
  # ported yet, so `ArchiveParams` is left out rather than given a type with
  # nothing real to fill it — the pages that would use it
  # (setup_transfer_settings_page, setup_transfer_option_row) are left out of
  # this round for the same reason.
  #
  # `SetupCommandLineArgs::from_str` upstream calls
  # `crate::utils::borg::parse_borg_command_line_args`, which is not ported
  # either; Ruby's standard `Shellwords` does the same job (POSIX shell word
  # splitting) and is used here instead.

  # `SetupAction` ("PkSetupKind" upstream): which of the two wizard flows is
  # running.
  module SetupAction
    INIT = :init
    ADD_EXISTING = :add_existing

    DEFAULT = INIT
  end

  # `SetupLocationKind` ("PkSetupRepoKind" upstream): which location-kind
  # page the wizard is on.
  module SetupLocationKind
    LOCAL = :local
    REMOTE = :remote

    DEFAULT = LOCAL
  end

  # `SetupRepoLocation`: either a local `Gio::File` or a remote borg/ssh URI
  # string, with upstream's URL-parsing rules for turning what the user typed
  # into one or the other.
  class SetupRepoLocation
    attr_reader :kind, :value

    def self.from_file(file) = new(:local, file)

    def self.local(file) = from_file(file)

    def self.remote(uri) = new(:remote, uri)

    # `SetupRepoLocation::parse_url`: parses borg's `user@host:path` shorthand
    # and canonicalizes it to `ssh://`, passing every other URI through
    # unchanged. Returns `[location, nil]` on success and `[nil, error]`
    # (an error message string) on failure — the two halves of upstream's
    # `Result<Self, String>`.
    def self.parse_url(input)
      input = input.to_s
      url = input.include?("://") ? input : borg_shorthand_to_url(input)

      return [nil, "Incomplete URL or borg syntax"] if url.nil?

      parse_canonical_url(url)
    end

    def self.borg_shorthand_to_url(input)
      target, path = input.split(":", 2)
      return nil if path.nil?

      url_path =
        if path.start_with?("~")
          "/#{path}"
        elsif path.start_with?("/")
          path
        else
          "/./#{path}"
        end

      "ssh://#{target}#{url_path}"
    end

    # The Ruby bindings have no `GLib::Uri`; `URI.parse` from the standard
    # library validates and splits the same RFC 3986 syntax upstream's
    # `glib::Uri::parse` does.
    def self.parse_canonical_url(url)
      uri = URI.parse(url)

      if uri.path.to_s.empty?
        [nil, "The remote location must have a specified path."]
      elsif uri.scheme == "ssh"
        [remote(url), nil]
      else
        [local(Gio::File.new_for_uri(url)), nil]
      end
    rescue URI::InvalidURIError => e
      [nil, "Invalid remote location: “#{e.message}”"]
    end

    def initialize(kind, value)
      @kind = kind
      @value = value
    end

    def local? = kind == :local

    def remote? = kind == :remote

    def to_s
      local? ? value.uri : value.to_s
    end
  end

  # `SetupCommandLineArgs`: the extra borg arguments typed into the
  # advanced-options page, stored as the shell-word-split list upstream
  # keeps, with the same round-trip back to one shell-quoted string.
  class SetupCommandLineArgs
    attr_reader :words

    def self.from_s(text)
      new(Shellwords.split(text.to_s))
    rescue ArgumentError
      # Shellwords raises on unmatched quoting; upstream's borg-syntax parser
      # would reject the same input, so this surfaces as "no arguments"
      # rather than raising through a UI call site.
      new([])
    end

    def initialize(words = [])
      @words = Array(words).map(&:to_s)
    end

    def empty? = words.empty?

    def to_a = words.dup

    def to_s = Shellwords.join(words)

    def ==(other) = other.is_a?(SetupCommandLineArgs) && other.words == words
  end

  SetupCommandLineArgs::NONE = SetupCommandLineArgs.new([]).freeze
end
