# frozen_string_literal: true

require "gtk4"

module PikaBackup
  # Weekday is the day a weekly backup prefers, and the model behind the
  # schedule page's weekday combo row.
  #
  # Ported from pika-backup/src/widget/detail/schedule/weekday.rs. Upstream
  # wraps `chrono::Weekday` in a GObject whose `display` property is the
  # localized day name; it gets that name by formatting a date in March 2021
  # with `%A`, because the 1st of that month was a Monday, so the day of the
  # month and the day of the week line up. This keeps that trick — Ruby's own
  # `strftime` is not localized, while GLib's `format` is.
  class Weekday < Data.define(:symbol)
    # Monday first, as upstream's LIST is.
    SYMBOLS = %i[monday tuesday wednesday thursday friday saturday sunday].freeze

    # Upstream's Default is Friday.
    DEFAULT_SYMBOL = :friday

    # The March 2021 whose 1st is a Monday.
    REFERENCE_YEAR = 2021
    REFERENCE_MONTH = 3

    def self.list = SYMBOLS.map { |symbol| new(symbol: symbol) }

    def self.default = new(symbol: DEFAULT_SYMBOL)

    def self.names = list.map(&:name)

    def self.string_list = Gtk::StringList.new(names)

    def self.index_of(symbol) = SYMBOLS.index(symbol)

    # 1 for Monday through 7 for Sunday, upstream's `number_from_monday`.
    def number_from_monday = SYMBOLS.index(symbol) + 1

    def name
      GLib::DateTime.new(
        year:   REFERENCE_YEAR,
        month:  REFERENCE_MONTH,
        day:    number_from_monday,
        hour:   0,
        minute: 0,
        second: 0,
      ).format("%A")
    end
  end
end
