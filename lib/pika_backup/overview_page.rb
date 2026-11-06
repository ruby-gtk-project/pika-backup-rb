# frozen_string_literal: true

require "adwaita"
require_relative "overview_row"

module PikaBackup
  # OverviewPage is the app's landing page: an empty-state status page while
  # no backup is configured, and a boxed list of OverviewRow otherwise.
  #
  # Ported from pika-backup/src/widget/overview.rs and overview.ui. Upstream
  # reads its rows from the global `BACKUP_CONFIG` store and rebuilds the list
  # whenever the GtkListBox is mapped; that store is not ported yet, so this
  # page takes its backups as a plain array and a public `backups=` setter
  # stands in for the config store notifying it of a change. `add_backup` is
  # upstream's `add_backup`/`add_backup_empty` buttons, both of which open
  # SetupDialog — not ported yet, so this takes the same callback-injection
  # the row takes rather than reaching for a window.
  #
  # The primary menu is Application's own menu button content; this page only
  # hosts the button, exactly as upstream's overview.ui does.
  class OverviewPage < Adwaita::NavigationPage
    TITLE = "Pika Backup"

    EMPTY_ICON = "overview-symbolic"
    EMPTY_TITLE = "No Backup Configured"
    EMPTY_DESCRIPTION = "Add a new configuration to start creating backups"
    EMPTY_BUTTON_LABEL = "_Setup Backup"

    def initialize(backups: [], on_add_backup: nil, on_view_backup: nil, on_view_schedule: nil)
      super(toolbar_view, TITLE)
      @backups = backups
      @on_add_backup = on_add_backup
      @on_view_backup = on_view_backup
      @on_view_schedule = on_view_schedule
    end

    def build
      tap do
        toolbar_view.tap do |view|
          view.add_top_bar(header_bar)
          view.content = content_box
        end

        header_bar.tap do |bar|
          bar.pack_start(add_backup_button)
        end

        content_box.tap do |box|
          box.append(main_stack)
        end

        main_stack.tap do |stack|
          stack.add(empty_page)
          stack.add(preferences_page)
        end

        preferences_page.tap do |page|
          page.add(preferences_group)
        end

        preferences_group.tap do |group|
          group.add(main_backups)
        end

        empty_page.child = add_backup_empty_button

        add_backup_button.signal_connect("clicked") { @on_add_backup&.call }
        add_backup_empty_button.signal_connect("clicked") { @on_add_backup&.call }

        rebuild_list
      end
    end

    # The primary menu button is Application's content, not this page's — it
    # only has to land on this page's header bar, exactly as overview.ui's
    # `end` child does.
    def add_header_end(widget) = header_bar.pack_end(widget)

    attr_reader :backups

    # Stands in for upstream's `BACKUP_CONFIG` store notifying the page of a
    # change; upstream rebuilds on the GtkListBox's `map` signal, which this
    # port has no equivalent trigger for without that store.
    def backups=(backups)
      @backups = backups
      rebuild_list
    end

    def reload_visible_page
      if @backups.empty?
        main_stack.visible_child = empty_page
      else
        main_stack.visible_child = preferences_page
      end
    end

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
    def header_bar = @header_bar ||= Adwaita::HeaderBar.new

    def add_backup_button
      @add_backup_button ||= Gtk::Button.new.tap do |button|
        button.icon_name = "list-add-symbolic"
        button.tooltip_text = "Setup Backup"
      end
    end

    def content_box
      @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.hexpand = true
        box.vexpand = true
      end
    end

    def main_stack = @main_stack ||= Adwaita::ViewStack.new.tap { |stack| stack.vexpand = true }

    def empty_page
      @empty_page ||= Adwaita::StatusPage.new.tap do |page|
        page.icon_name = EMPTY_ICON
        page.title = EMPTY_TITLE
        page.description = EMPTY_DESCRIPTION
      end
    end

    def add_backup_empty_button
      @add_backup_empty_button ||= Gtk::Button.new.tap do |button|
        button.label = EMPTY_BUTTON_LABEL
        button.use_underline = true
        button.halign = :center
        button.add_css_class("pill")
        button.add_css_class("suggested-action")
      end
    end

    def preferences_page = @preferences_page ||= Adwaita::PreferencesPage.new
    def preferences_group = @preferences_group ||= Adwaita::PreferencesGroup.new

    def main_backups
      @main_backups ||= Gtk::ListBox.new.tap do |box|
        box.valign = :start
        box.selection_mode = :none
        box.add_css_class("overview-list")
      end
    end

    private

      def rebuild_list
        rows.each { |row| main_backups.remove(row) }
        @rows = @backups.map do |config|
          OverviewRow.new(
            config,
            on_view_backup:   @on_view_backup,
            on_view_schedule: @on_view_schedule,
          ).build.tap { |row| main_backups.append(row) }
        end

        reload_visible_page
      end

      def rows = @rows ||= []
  end
end
