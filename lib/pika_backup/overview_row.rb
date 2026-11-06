# frozen_string_literal: true

require "adwaita"
require_relative "location_tag"
require_relative "status_row"

module PikaBackup
  # OverviewRow is one backup setup's row on the overview page: a boxed list
  # of a location row (icon, title, subtitle, included-folder tags), a status
  # row and a schedule-status row.
  #
  # Ported from pika-backup/src/widget/overview/row.rs and row.ui. Upstream
  # subclasses GtkListBoxRow, takes a `common::config::Backup` as a
  # construct-only property, and wires the location row's and the schedule
  # row's `activated` signals straight to `AppWindow#view_backup_conf` and
  # `SchedulePage#view`. Neither the detail page nor the navigation between
  # pages is ported yet, so this takes the two callbacks as constructor
  # arguments instead of reaching for a window through `root`.
  #
  # `config` is duck-typed to whatever answers `id`, `title`, `include` (an
  # array of paths) and `repo` (itself answering `icon` and `subtitle`) —
  # upstream's `common::config::Backup` and `config::Repository`, neither of
  # which is ported yet.
  #
  # The status row and the schedule-status row are left at the title upstream
  # gives a backup that has never run and a schedule that has never been set,
  # because the status-tracking and scheduling backends
  # (pika-backup/src/backup_status.rs, pika-backup/src/widget/detail/schedule)
  # are not ported yet either. `refresh_status` is the seam a future port of
  # those hangs a real status off, the way upstream's `force_refresh_status`
  # does.
  class OverviewRow < Gtk::ListBoxRow
    NEVER_RUN_ICON = "dialog-information-symbolic"
    NEVER_RUN_TITLE = "Backup Never Run"
    NEVER_RUN_SUBTITLE = "Begin by carrying out your first backup"

    NO_SCHEDULE_ICON = "schedule-symbolic"
    NO_SCHEDULE_TITLE = "Not Scheduled"

    def initialize(config, on_view_backup: nil, on_view_schedule: nil)
      super()
      @config = config
      @on_view_backup = on_view_backup
      @on_view_schedule = on_view_schedule
      self.activatable = false
      add_css_class("overview-row")
    end

    def build
      tap do
        self.child = list_box

        list_box.tap do |box|
          box.append(location_row)
          box.append(status.build)
          box.append(schedule_status.build)
        end

        location_row.tap do |row|
          row.add_prefix(location_prefix)
          row.add_suffix(Gtk::Image.new(icon_name: "go-next-symbolic").tap { |i| i.add_css_class("dim-label") })
          row.signal_connect("activated") { @on_view_backup&.call(@config) }
        end

        location_prefix.tap do |box|
          box.append(location_icon)
          box.append(location_text_box)
        end

        location_text_box.tap do |box|
          box.append(location_title)
          box.append(location_subtitle)
          box.append(include_box)
        end

        @config.include.each do |path|
          include_box.append(LocationTag.from_path(path).build)
        end

        schedule_status.tap do |row|
          row.activatable = true
          row.add_suffix(Gtk::Image.new(icon_name: "go-next-symbolic").tap { |i| i.add_css_class("dim-label") })
          row.signal_connect("activated") { @on_view_schedule&.call(@config) }
        end

        refresh_status
      end
    end

    attr_reader :status, :schedule_status

    # Upstream's `force_refresh_status`, minus the status-tracking and
    # scheduling backends it reads from.
    def refresh_status
      status.apply_status(
        title:    NEVER_RUN_TITLE,
        subtitle: NEVER_RUN_SUBTITLE,
        graphic:  StatusIcon::Graphic.warning_icon(NEVER_RUN_ICON),
      )

      schedule_status.apply_status(
        title:   NO_SCHEDULE_TITLE,
        graphic: StatusIcon::Graphic.new(level: :neutral, icon_name: NO_SCHEDULE_ICON),
      )
    end

    def list_box
      @list_box ||= Gtk::ListBox.new.tap do |box|
        box.selection_mode = :none
        box.add_css_class("boxed-list")
      end
    end

    def location_row
      @location_row ||= Adwaita::ActionRow.new.tap do |row|
        row.activatable = true
      end
    end

    def location_prefix
      @location_prefix ||= Gtk::Box.new(:horizontal, 6).tap do |box|
        box.margin_top = 6
        box.margin_bottom = 6
      end
    end

    # Upstream resolves `config.repo.icon()` through `gio::Icon::for_string`,
    # which accepts either a plain themed icon name or a serialized GIcon. The
    # Ruby bindings expose no equivalent parser, and every repository kind
    # this port knows about names a themed icon, so the icon name is used
    # directly.
    def location_icon
      @location_icon ||= Gtk::Image.new(icon_name: @config.repo.icon.to_s).tap do |image|
        image.valign = :start
        image.pixel_size = 64
      end
    end

    def location_text_box
      @location_text_box ||= Gtk::Box.new(:vertical, 3).tap do |box|
        box.hexpand = true
        box.add_css_class("overview-location-box")
      end
    end

    def location_title
      @location_title ||= Gtk::Label.new(@config.title.to_s).tap do |label|
        label.xalign = 0
        label.wrap = true
        label.add_css_class("heading")
      end
    end

    def location_subtitle
      @location_subtitle ||= Gtk::Label.new(@config.repo.subtitle.to_s).tap do |label|
        label.xalign = 0
        label.wrap = true
        label.add_css_class("subtitle")
      end
    end

    def include_box
      @include_box ||= Adwaita::WrapBox.new.tap do |box|
        box.child_spacing = 5
        box.line_spacing = 5
        box.add_css_class("tag-box")
        box.add_css_class("caption")
      end
    end

    def status = @status ||= StatusRow.new
    def schedule_status = @schedule_status ||= StatusRow.new
  end
end
