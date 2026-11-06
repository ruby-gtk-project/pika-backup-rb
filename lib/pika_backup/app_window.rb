# frozen_string_literal: true

require "adwaita"
require_relative "overview_page"

module PikaBackup
  # AppWindow is the application's single window: a toast overlay around a
  # navigation view, which holds the overview page and, once it is ported,
  # the detail page.
  #
  # Ported from pika-backup/src/widget/app_window.rs and app_window.ui.
  # Upstream is an AdwApplicationWindow subclass that reloads the overview
  # page whenever the navigation view returns to it, and shows the detail
  # page directly on map when exactly one backup is configured; it also
  # guards window close behind `App#try_quit` and decorates the header bar
  # for pre-release builds. None of that survives here: the detail page
  # (pika-backup/src/widget/detail.rs) is not ported, there is no `App`
  # subclass to guard quitting through, and there is no build-time
  # `APPLICATION_ID_SUFFIX`. What is ported is the window's geometry, the
  # toast overlay, and the navigation view holding the overview page.
  #
  # The ruby-gtk skill's quirks reference flags Adwaita::ApplicationWindow as
  # broken for *composition* ("MainWindow(app) still fails with type
  # errors") — wrapping it behind a plain Ruby object that merely holds one.
  # Subclassing it directly works fine in this binding, and only a subclass
  # gets `content=` and `visible_dialog` instead of a bare Gtk::ApplicationWindow,
  # which the rest of this port's dialogs (ShortcutsDialog, AboutDialog) are
  # already written to present against.
  class AppWindow < Adwaita::ApplicationWindow
    TITLE = "Pika Backup"

    WIDTH_REQUEST = 360
    HEIGHT_REQUEST = 294
    DEFAULT_WIDTH = 782
    DEFAULT_HEIGHT = 665

    def initialize(app, overview_page:)
      super(app)
      @overview_page = overview_page
      self.title = TITLE
      self.width_request = WIDTH_REQUEST
      self.height_request = HEIGHT_REQUEST
      set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    end

    def build
      tap do
        self.content = toast_overlay
        toast_overlay.child = navigation_view
        navigation_view.push(@overview_page)
      end
    end

    # Upstream's `AdwToastOverlay#add_toast`; this is the seam
    # UiUtils/toast-raising code (not ported yet) hangs a real toast off.
    def add_toast(toast) = toast_overlay.add_toast(toast)

    def toast_overlay = @toast_overlay ||= Adwaita::ToastOverlay.new
    def navigation_view = @navigation_view ||= Adwaita::NavigationView.new
  end
end
