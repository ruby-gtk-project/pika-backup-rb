# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # SpinnerPage is the base class for every "working on it" page in a
  # navigation view: a header bar with no title and no title buttons, and a
  # status page whose icon is a spinner.
  #
  # Ported from pika-backup/src/widget/navigation/spinner_page.rs and
  # spinner_page.ui. The page cannot be popped — upstream sets `can-pop` false
  # — because the operation it reports on has to finish or fail first.
  class SpinnerPage < Adwaita::NavigationPage
    def initialize(title = "", description = nil)
      super(toolbar_view, title)
      self.can_pop = false
      add_css_class("spinner-page")
      @description = description
    end

    def build
      tap do
        toolbar_view.tap do |view|
          view.add_top_bar(header_bar)
          view.content = status_page
        end

        status_page.tap do |page|
          page.paintable = spinner_paintable
          page.title = title.to_s
          page.description = @description.to_s
        end

        # Upstream's `shown` vfunc moves focus to the status page so a screen
        # reader announces the operation when the page appears. The Ruby
        # bindings cannot override that vfunc; the `shown` signal is the same
        # notification.
        signal_connect("shown") { status_page.grab_focus }
      end
    end

    # Upstream binds the status page's title to the page's own `title`.
    def title=(title)
      super
      status_page.title = title.to_s
    end

    attr_reader :description

    def description=(description)
      @description = description
      status_page.description = description.to_s
    end

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

    def header_bar
      @header_bar ||= Adwaita::HeaderBar.new.tap do |bar|
        bar.show_start_title_buttons = false
        bar.show_end_title_buttons = false
        bar.title_widget = Adwaita::Bin.new
      end
    end

    def status_page
      @status_page ||= Adwaita::StatusPage.new.tap do |page|
        page.focusable = true
        page.vexpand = true
      end
    end

    # The spinner animates against the widget it is drawn in, so the status
    # page has to exist before the paintable does.
    def spinner_paintable = @spinner_paintable ||= Adwaita::SpinnerPaintable.new(status_page)
  end
end
