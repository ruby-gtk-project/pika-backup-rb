# frozen_string_literal: true

require "gtk4"

module PikaBackup
  # Keep is how many archives of each period a prune run keeps.
  #
  # Ported from `common::config::Keep` in
  # pika-backup-common/src/config/prune.rs. It lives here because PrunePreset
  # is its only consumer so far; it moves to the config component when that is
  # ported.
  class Keep < Data.define(
    :hourly,
    :daily,
    :weekly,
    :monthly,
    :yearly,
  )
    # Upstream's `Default for Keep`.
    def self.default
      new(
        hourly:  48,
        daily:   14,
        weekly:  4,
        monthly: 12,
        yearly:  10,
      )
    end

    # Upstream's `is_greater_eq_everywhere`: this policy keeps at least as much
    # as the other one in every period.
    def greater_eq_everywhere?(other)
      hourly >= other.hourly &&
        daily >= other.daily &&
        weekly >= other.weekly &&
        monthly >= other.monthly &&
        yearly >= other.yearly
    end
  end

  # PrunePreset is the model behind the schedule page's "keep archives" combo
  # row: two ready-made retention policies, plus Custom for a hand-edited one.
  #
  # Ported from pika-backup/src/widget/detail/schedule/prune_preset.rs.
  # Upstream wraps the enum in a GObject and builds a GioListStore of them so a
  # combo row can list them; the Ruby bindings list a combo row from a
  # Gtk::StringList of display names, so `string_list` takes the place of
  # upstream's `list_store`.
  class PrunePreset < Data.define(:kind)
    KINDS = %i[keep_many keep_some custom].freeze

    NAMES = {
      keep_many: "Keep Many",
      keep_some: "Keep Some",
      custom:    "Custom",
    }.freeze

    def self.keep_many = new(kind: :keep_many)
    def self.keep_some = new(kind: :keep_some)
    def self.custom = new(kind: :custom)

    # Upstream's Default is Custom.
    def self.default = custom

    def self.list = [keep_many, keep_some, custom]

    def self.names = list.map(&:name)

    def self.string_list = Gtk::StringList.new(names)

    def self.index_of(kind) = KINDS.index(kind)

    # Upstream's `matching`: the first preset whose policy is exactly the
    # configured one, and Custom when none is.
    def self.matching(keep)
      list.find { |preset| preset.keep == keep } || custom
    end

    def name = NAMES.fetch(kind)

    # Custom has no policy of its own — it means "whatever the user typed".
    def keep
      case kind
      when :keep_many
        Keep.default
      when :keep_some
        Keep.new(
          hourly:  24,
          daily:   7,
          weekly:  2,
          monthly: 6,
          yearly:  0,
        )
      end
    end

    def custom? = kind == :custom
  end
end
