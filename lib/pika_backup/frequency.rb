# frozen_string_literal: true

require "gtk4"

module PikaBackup
  # Frequency is how often a scheduled backup runs, and the model behind the
  # schedule page's frequency combo row.
  #
  # Ported from pika-backup/src/widget/detail/schedule/frequency.rs, which
  # wraps `common::config::Frequency` (pika-backup-common/src/config/schedule.rs)
  # in a GObject so a combo row can list it. The Ruby bindings list a combo row
  # from a Gtk::StringList of display names, so that GObject wrapper has no
  # counterpart here: this is the config value itself, plus the `names` and
  # `string_list` the combo row needs.
  #
  # Each kind carries the one preference it needs — the time of day, the day of
  # the week, or the day of the month — exactly as upstream's enum variants do.
  class Frequency < Data.define(
    :kind,
    :preferred_time,
    :preferred_weekday,
    :preferred_day,
  )
    KINDS = %i[hourly daily weekly monthly].freeze

    NAMES = {
      hourly:  "Hourly",
      daily:   "Daily",
      weekly:  "Weekly",
      monthly: "Monthly",
    }.freeze

    # Upstream's `Default for Frequency`: daily at 17:00.
    DEFAULT_HOUR = 17

    def self.hourly
      new(
        kind:              :hourly,
        preferred_time:    nil,
        preferred_weekday: nil,
        preferred_day:     nil,
      )
    end

    def self.daily(hour: 0, minute: 0)
      new(
        kind:              :daily,
        preferred_time:    [hour, minute],
        preferred_weekday: nil,
        preferred_day:     nil,
      )
    end

    def self.weekly(preferred_weekday: :monday)
      new(
        kind:              :weekly,
        preferred_time:    nil,
        preferred_weekday: preferred_weekday,
        preferred_day:     nil,
      )
    end

    def self.monthly(preferred_day: 1)
      new(
        kind:              :monthly,
        preferred_time:    nil,
        preferred_weekday: nil,
        preferred_day:     preferred_day,
      )
    end

    def self.default = daily(hour: DEFAULT_HOUR)

    # Upstream's `list()`: one of each kind, carrying the neutral preference
    # values the combo row starts from — midnight, Monday, the first of the
    # month.
    def self.list = [hourly, daily, weekly, monthly]

    def self.names = list.map(&:name)

    def self.string_list = Gtk::StringList.new(names)

    # The row a combo row should select for a configured frequency, which
    # depends only on the kind.
    def self.index_of(kind) = KINDS.index(kind)

    def name = NAMES.fetch(kind)

    def hourly? = kind == :hourly
    def daily? = kind == :daily
    def weekly? = kind == :weekly
    def monthly? = kind == :monthly
  end
end
