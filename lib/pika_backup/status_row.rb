# frozen_string_literal: true

require "adwaita"
require_relative "status_icon"

module PikaBackup
  # StatusRow is an AdwActionRow with a StatusIcon as its prefix: the shape
  # every "last backup / last check / schedule" line in the app uses.
  #
  # Ported from pika-backup/src/widget/status_row.rs. Upstream subclasses
  # AdwActionRow, adds the StatusIcon as a prefix, pins the subtitle to one
  # line, adds the `numeric` CSS class, and binds its own `icon-name` and
  # `level` properties through to the icon. The Ruby bindings cannot add
  # GObject properties to a Ruby subclass, so the two accessors write through
  # to the icon directly instead of being bound.
  class StatusRow < Adwaita::ActionRow
    def initialize(title = "", subtitle = "", icon_name = "", level = :neutral)
      super()
      self.title = title.to_s
      self.subtitle = subtitle.to_s
      self.subtitle_lines = 1
      add_css_class("numeric")
      @icon_name = icon_name
      @level = level
    end

    def build
      tap do
        add_prefix(status_icon.build)

        status_icon.icon_name = @icon_name
        status_icon.level = @level
      end
    end

    def icon_name = status_icon.icon_name

    def icon_name=(icon_name)
      @icon_name = icon_name
      status_icon.icon_name = icon_name
    end

    def level = status_icon.level

    def level=(level)
      @level = level
      status_icon.level = level
    end

    # Upstream's `set_from_backup_status`, which takes a `backup_status::Display`.
    # That component is not ported yet, so this takes the three fields of it
    # that the row actually renders. An AdwActionRow title and subtitle are
    # Pango markup, so both are escaped exactly as upstream escapes them.
    def apply_status(title:, graphic:, subtitle: nil)
      tap do
        self.title = self.class.escape_markup(title)
        self.subtitle = self.class.escape_markup(subtitle)
        status_icon.set_from_graphic(graphic)
      end
    end

    def status_icon = @status_icon ||= StatusIcon.new

    # The five entities g_markup_escape_text replaces. The Ruby GLib bindings
    # do not expose that function, so the substitution is spelled out.
    MARKUP_ENTITIES = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      "'" => "&apos;",
      '"' => "&quot;",
    }.freeze

    def self.escape_markup(text) = text.to_s.gsub(/[&<>'"]/, MARKUP_ENTITIES)
  end
end
