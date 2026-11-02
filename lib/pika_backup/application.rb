# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "about_dialog"
require_relative "shortcuts_dialog"

module PikaBackup
  # The port's application object: the stylesheet, the app-level actions and
  # their accelerators, the primary menu, and the window they all hang off.
  #
  # Ported from pika-backup/src/app.rs — specifically its `setup_actions`, the
  # two `set_accels_for_action` calls, and the primary menu that
  # pika-backup/src/widget/overview.ui declares. The actions that drive pages
  # and dialogs this port has not reached yet (`setup`, `backup-preferences`,
  # `remove`, `backup.start`, `backup.show`, and the D-Bus actions) are not
  # registered, so the menu shows only what works.
  #
  # The window's geometry is app_window.ui's. Its content is not: upstream puts
  # an AdwNavigationView holding the overview and detail pages there, and
  # neither page is ported yet, so the window shows a status page naming what
  # the port can reach instead.
  #
  # House style (see .claude/skills/ruby-gtk): every widget is a memoized
  # method, all configuration lives in its `tap`, assembly happens only in
  # `build`, and the launcher is one expression.
  class Application
    APPLICATION_ID = "org.rubygtkproject.PikaBackup"

    HELP_URI = "help:pika-backup"

    # app_window.ui's geometry.
    WIDTH_REQUEST = 360
    HEIGHT_REQUEST = 294
    DEFAULT_WIDTH = 782
    DEFAULT_HEIGHT = 665

    TITLE = "Pika Backup"

    # overview.ui's primary menu, in its order.
    MENU_ITEMS = [
      ["_Keyboard Shortcuts", "app.shortcuts"],
      ["_Help", "app.help"],
      ["_About Pika Backup", "app.about"],
    ].freeze

    # app.rs sets the first two; app_window.ui binds Ctrl+? to the shortcuts
    # window through a GtkShortcutController.
    ACCELS = {
      "app.help"      => ["F1"],
      "app.quit"      => ["<Ctrl>Q", "<Ctrl>W"],
      "app.shortcuts" => ["<Ctrl>question"],
    }.freeze

    STYLESHEET = File.expand_path("style.css", __dir__)
    ICONS = File.expand_path("icons", __dir__)

    def build
      app.tap do
        app.signal_connect("startup") do
          # Without this libadwaita's own stylesheet is never loaded and every
          # window renders in GTK's default theme — no Adwaita typography, no
          # rounded cards, and none of the `--success-color` style variables
          # style.css builds the status badges out of. Requiring the binding
          # does not do it, and the Gtk::Application used here is not the
          # Adwaita::Application that would.
          Adwaita.init
          register_icons
          load_stylesheet
          register_actions
        end

        app.signal_connect("activate") do
          window.tap do |win|
            win.content = toolbar_view
          end

          toolbar_view.tap do |view|
            view.add_top_bar(header_bar)
            view.content = status_page
          end

          header_bar.pack_end(menu_button)

          window.present
        end
      end
    end

    def run = app.run([])

    # Adwaita::Application is unreliable in the Ruby bindings; the application
    # object comes from Gtk and only the window is Adwaita.
    def app = @app ||= Gtk::Application.new(APPLICATION_ID, :default_flags)

    def window
      @window ||= Adwaita::ApplicationWindow.new(app).tap do |win|
        win.title = TITLE
        win.width_request = WIDTH_REQUEST
        win.height_request = HEIGHT_REQUEST
        win.set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT)
      end
    end

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
    def header_bar = @header_bar ||= Adwaita::HeaderBar.new

    def menu_button
      @menu_button ||= Gtk::MenuButton.new.tap do |button|
        button.menu_model = menu
        button.icon_name = "open-menu-symbolic"
        button.tooltip_text = "Main Menu"
        button.primary = true
      end
    end

    def menu
      @menu ||= Gio::Menu.new.tap do |model|
        MENU_ITEMS.each { |label, action| model.append(label, action) }
      end
    end

    # Scaffolding, not upstream UI: it stands in for the overview page until
    # that is ported, and names the parts of the port that already work.
    def status_page
      @status_page ||= Adwaita::StatusPage.new.tap do |page|
        page.icon_name = "overview-symbolic"
        page.title = TITLE
        page.description = "The main menu reaches the keyboard shortcuts, the help and the about dialog. " \
                           "The overview of configured backups is not ported yet."
      end
    end

    private

    # Upstream ships its own symbolic icons in a GResource bundle, which is
    # where names like `check-round-outline-symbolic` and `overview-symbolic`
    # come from — they are not in the system icon theme. The port keeps the
    # same SVGs on disk and puts their directory on the icon theme's search
    # path. A search path is scanned as `<dir>/<theme>/<size>/<context>/`, one
    # level deeper than the GResource path upstream registers, so the icons sit
    # under `icons/hicolor/scalable/` rather than upstream's `icons/scalable/`.
      def register_icons
        Gtk::IconTheme.get_for_display(Gdk::Display.default).add_search_path(ICONS)
      end

      def load_stylesheet
        Gtk::CssProvider.new.tap do |provider|
          provider.load(path: STYLESHEET)

          Gtk::StyleContext.add_provider_for_display(
            Gdk::Display.default,
            provider,
            Gtk::StyleProvider::PRIORITY_APPLICATION,
          )
        end
      end

      def register_actions
        actions.each do |name, handler|
          Gio::SimpleAction.new(name).tap do |action|
            action.signal_connect("activate") { handler.call }
            app.add_action(action)
          end
        end

        ACCELS.each { |action, accels| app.set_accels_for_action(action, accels) }
      end

      def actions
        {
          "about"     => method(:present_about),
          "shortcuts" => method(:present_shortcuts),
          "help"      => method(:launch_help),
          "quit"      => method(:quit),
        }
      end

      def present_about = AboutDialog.new.build.present(window)

    # Upstream never registers `app.shortcuts` itself: its AdwApplication
    # installs that action, and shortcuts-dialog.ui is the dialog it shows.
    # This port's application object is a Gtk::Application, so the action has
    # to be registered here.
      def present_shortcuts = ShortcutsDialog.new.build.present(window)

      def launch_help
        Gio::AppInfo.launch_default_for_uri(HELP_URI, nil)
      rescue GLib::Error
        nil
      end

    # Upstream guards quitting against running backup operations. The
    # operation tracking is not ported, so this is upstream's unguarded path —
    # the one it takes when nothing is running.
      def quit = app.quit
  end
end
