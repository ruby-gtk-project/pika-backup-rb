# frozen_string_literal: true

require "adwaita"
require_relative "../pika/backup/rb/version"

module PikaBackup
  # AboutDialog is the app's about window, including the two long explanatory
  # sections upstream puts in its comments field and the debug report the issue
  # tracker asks for.
  #
  # Ported from pika-backup/src/widget/dialog/about.rs.
  class AboutDialog < Adwaita::AboutDialog
    # Translators' note carried over from upstream: "Pika" refers to a small
    # mammal (https://en.wikipedia.org/wiki/Pika). A transliteration must not
    # collide with a different meaning.
    APPLICATION_NAME = "Pika Backup"

    APP_ID = "org.gnome.World.PikaBackup"
    WEBSITE = "https://apps.gnome.org/PikaBackup/"
    ISSUE_URL = "https://gitlab.gnome.org/World/pika-backup/-/issues"

    # Do not translate, only transliterate if necessary.
    DEVELOPER_NAME = "Small Mammal Collective"

    DEVELOPERS = [
      "Sophie Herold <sophieherold@gnome.org>",
      "Fina Wilke <finaw@gnome.org>",
    ].freeze

    ARTISTS = [
      "Jakub Steiner",
      "Tobias Bernard",
    ].freeze

    COPYRIGHT = "Copyright © 2018–2023 Sophie Herold et al."

    BACK_END_HEADING = "Back End"
    BACK_END_TEXT = "Pika Backup uses BorgBackup. This app wouldn’t exist without Borg. " \
                    "Consider <a href='https://www.borgbackup.org/support/fund.html'>supporting BorgBackup</a>."

    NAME_HEADING = "The Name"
    NAME_TEXT = "The name “Pika Backup” derives from the American pika. Pikas are small mammals " \
                "belonging to the lagomorphs. The American pika is known for caching food in " \
                "skillfully constructed haypiles. Techniques used by American pikas for building " \
                "haypiles include: storing piles below overhanging rocks, using certain plants which " \
                "inhibit bacterial growth as preservative and preferring plants with high nutrition " \
                "value for haying. Last but not least, pikas do not only create very sophisticated " \
                "haypiles but are quick in collecting vegetation as well."

    RUMOUR_TEXT = "Frequent rumors that this software’s name is related to a monster with " \
                  "electrical abilities are unfounded."

    LINKS = [
      ["Support us on Open Collective", "https://opencollective.com/pika-backup"],
      ["Support us on GitHub Sponsors", "https://github.com/sponsors/pika-backup/"],
    ].freeze

    def initialize
      super()
      self.application_name = APPLICATION_NAME
      self.application_icon = APP_ID
      self.version = Pika::Backup::Rb::VERSION
      self.website = WEBSITE
      self.issue_url = ISSUE_URL
      self.developer_name = DEVELOPER_NAME
      self.developers = DEVELOPERS
      self.artists = ARTISTS
      self.copyright = COPYRIGHT
      self.translator_credits = "translator-credits"
      self.comments = comments_markup
      self.debug_info = debug_report
    end

    def build
      tap do
        LINKS.each { |title, url| add_link(title, url) }
      end
    end

    # Upstream formats the comments as two bold headings with a paragraph each,
    # then the closing line, using Pango markup.
    def comments_markup
      [
        heading(BACK_END_HEADING),
        BACK_END_TEXT,
        "",
        heading(NAME_HEADING),
        NAME_TEXT,
        "",
        RUMOUR_TEXT,
      ].join("\n")
    end

    # The report the issue tracker asks for. Upstream also reports the
    # BorgBackup version and the Flatpak sandbox details; neither the borg
    # backend nor the Flatpak information reader is ported yet, so those lines
    # are absent rather than reported as unknown.
    def debug_report
      [
        "- Version: #{Pika::Backup::Rb::VERSION}",
        "- App ID: #{APP_ID}",
        "- gtk: #{Gtk::Version::MAJOR}.#{Gtk::Version::MINOR}.#{Gtk::Version::MICRO}",
        "- libadwaita: #{Adwaita::MAJOR_VERSION}.#{Adwaita::MINOR_VERSION}.#{Adwaita::MICRO_VERSION}",
        "\n##### OS Information\n```\n#{os_release}\n```",
        "\n##### User Autostart\n```\n#{user_autostart}\n```",
        "\n##### Global Autostart\n```\n#{global_autostart}\n```",
      ].join("\n")
    end

    private

      def heading(text) = "<span line_height='1.6' weight='bold'>#{text}</span>"

    # Upstream reads the host's /etc through the sandbox's /run/host/etc when
    # it is sandboxed. The sandbox detection is not ported, so this reads /etc
    # directly, which is the un-sandboxed branch.
      def etc = "/etc"

      def os_release = read_or_empty(File.join(etc, "os-release"))

      def user_autostart
        read_or_empty(File.join(GLib.user_config_dir, "autostart", "#{APP_ID}.desktop"))
      end

      def global_autostart
        read_or_empty(
          File.join(
            etc,
            "xdg",
            "autostart",
            "#{APP_ID}.desktop",
          ),
        )
      end

    # Upstream's `unwrap_or_default` on every one of these reads: a missing or
    # unreadable file contributes an empty block, not an error.
      def read_or_empty(path)
        File.read(path)
      rescue SystemCallError, IOError
        ""
      end
  end
end
