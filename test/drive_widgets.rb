# frozen_string_literal: true

# Drives the ported window, its two dialogs, and every leaf widget ported so
# far, then screenshots each of them.

require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require_relative "gtk_driver"
require "pika_backup"

ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir

SHOTS = File.expand_path("../tmp/shots", __dir__)

application = PikaBackup::Application.new

# A gallery of the leaf widgets, assembled the way a page would assemble them.
def gallery
  Adwaita::PreferencesPage.new.tap do |page|
    page.add(status_group)
    page.add(folder_group)
  end
end

def status_group
  Adwaita::PreferencesGroup.new.tap do |group|
    group.title = "StatusRow levels"
    status_rows.each { |row| group.add(row) }
  end
end

def status_rows
  @status_rows ||= [
    PikaBackup::StatusRow.new(
      "Last Backup Successful",
      "2 hours ago",
      "check-round-outline-symbolic",
      :ok,
    ).build,
    PikaBackup::StatusRow.new(

      "No Integrity Check",

      "Archives integrity check not yet performed",
      "diagnostics-symbolic",

      :warning,
    ).build,
    PikaBackup::StatusRow.new(

      "Backup Never Run",

      "Begin by carrying out your first backup",
      "dialog-information-symbolic",

      :warning,
    ).build,
    PikaBackup::StatusRow.new(
      "Last Backup Failed",
      "4 days ago",
      "dialog-error-symbolic",
      :error,
    ).build,
    PikaBackup::StatusRow.new(
      "Backup Running",
      "38.2 % finished",
      "",
      :spinner,
    ).build,
  ]
end

def folder_group
  Adwaita::PreferencesGroup.new.tap do |group|
    group.title = "FolderRow"
    group.add(folder_row)
  end
end

def folder_row = @folder_row ||= PikaBackup::FolderRow.new.build

def tag_group
  @tag_group ||= Adwaita::PreferencesGroup.new.tap do |group|
    group.title = "LocationTag"
    group.add(tag_row)
  end
end

def tag_row
  @tag_row ||= Adwaita::ActionRow.new.tap do |row|
    row.title = "Included"
    row.add_suffix(tag_box)
  end
end

def tag_box
  @tag_box ||= Gtk::Box.new(:horizontal, 6).tap do |box|
    box.add_css_class("tag-box")
    box.append(PikaBackup::LocationTag.from_path("").build)
    box.append(PikaBackup::LocationTag.from_path("src").build)
    box.append(PikaBackup::LocationTag.from_path("No/Such/Folder").build)
  end
end

# A NavigationPage needs a navigation view to be shown in.
def page_host(page)
  Adwaita::NavigationView.new.tap { |view| view.add(page) }
end

GtkDriver.drive(application, shots: SHOTS) do |d, app|
  d.window { app.window }

  d.step("the combo-row models") do
    d.check("frequency names") do
      PikaBackup::Frequency.names == ["Hourly", "Daily", "Weekly", "Monthly"]
    end
    d.check("frequency default is daily at 17:00") do
      PikaBackup::Frequency.default.daily? && PikaBackup::Frequency.default.preferred_time == [17, 0]
    end
    d.check("frequency index_of(:weekly) is 2") { PikaBackup::Frequency.index_of(:weekly) == 2 }

    d.check("weekday names start at Monday") { PikaBackup::Weekday.names.first == "Monday" }
    d.check("weekday names end at Sunday") { PikaBackup::Weekday.names.last == "Sunday" }
    d.check("weekday default is Friday") { PikaBackup::Weekday.default.name == "Friday" }
    d.check("weekday number_from_monday") { PikaBackup::Weekday.new(symbol: :wednesday).number_from_monday == 3 }

    d.check("prune preset names") do
      PikaBackup::PrunePreset.names == ["Keep Many", "Keep Some", "Custom"]
    end
    d.check("keep_many keeps the config default") do
      PikaBackup::PrunePreset.keep_many.keep == PikaBackup::Keep.default
    end
    d.check("custom has no policy") { PikaBackup::PrunePreset.custom.keep.nil? }
    d.check("matching finds keep_some") do
      PikaBackup::PrunePreset.matching(PikaBackup::PrunePreset.keep_some.keep).kind == :keep_some
    end
    d.check("matching falls back to custom") do
      PikaBackup::PrunePreset.matching(
        PikaBackup::Keep.new(
          hourly: 1, daily: 1, weekly: 1, monthly: 1, yearly: 1,
        ),
      ).custom?
    end
    d.check("keep compares everywhere") do
      PikaBackup::Keep.default.greater_eq_everywhere?(PikaBackup::PrunePreset.keep_some.keep)
    end

    d.check("markup is escaped") do
      PikaBackup::StatusRow.escape_markup(%(a & b < c > d ' e " f)) ==
        "a &amp; b &lt; c &gt; d &apos; e &quot; f"
    end
  end

  d.step("the main window") do
    d.check("title") { app.window.title == "Pika Backup" }
    d.check("libadwaita is initialised") { Adwaita.initialized? }
    d.check("stylesheet loaded") { File.exist?(PikaBackup::Application::STYLESHEET) }
    d.check("the app icon resolves") do
      Gtk::IconTheme.get_for_display(Gdk::Display.default).has_icon?("org.gnome.World.PikaBackup")
    end
    d.check("upstream icons resolve") do
      theme = Gtk::IconTheme.get_for_display(Gdk::Display.default)
      %w[overview-symbolic check-round-outline-symbolic diagnostics-symbolic schedule-symbolic
         play-large-symbolic stop-large-symbolic tag-symbolic padlock-open-symbolic
].all? do |name|
        theme.has_icon?(name)
      end
    end
    d.check("menu has the three upstream items") { app.menu.n_items == 3 }
    d.check("menu button is primary") { app.menu_button.primary? }
    d.check("about action registered") { app.app.has_action?("about") }
    d.check("shortcuts action registered") { app.app.has_action?("shortcuts") }
    d.check("help action registered") { app.app.has_action?("help") }
    d.check("quit action registered") { app.app.has_action?("quit") }
    d.check("F1 is bound to help") { app.app.get_accels_for_action("app.help") == ["F1"] }
    d.check("Ctrl+Q and Ctrl+W quit") do
      app.app.get_accels_for_action("app.quit") == ["<Control>q", "<Control>w"]
    end
    d.shot("01-main-window")
  end

  d.step("open the shortcuts dialog") { app.app.activate_action("shortcuts", nil) }

  d.step("the shortcuts dialog is showing") do
    d.check("a dialog is up") { !app.window.visible_dialog.nil? }
    d.check("it is the shortcuts dialog") { app.window.visible_dialog.is_a?(PikaBackup::ShortcutsDialog) }
  end

  # Presenting a dialog animates it in, so the screenshot waits a tick.
  d.step("screenshot the shortcuts dialog") do
    d.shot("02-shortcuts-dialog")
    app.window.visible_dialog&.close
  end

  d.step("open the about dialog") { app.app.activate_action("about", nil) }

  d.step("the about dialog is showing") do
    d.check("a dialog is up") { !app.window.visible_dialog.nil? }
    d.check("it is the about dialog") { app.window.visible_dialog.is_a?(PikaBackup::AboutDialog) }
    d.check("version is set") { !app.window.visible_dialog.version.to_s.empty? }
    d.check("debug report names the app id") do
      app.window.visible_dialog.debug_info.include?("org.gnome.World.PikaBackup")
    end
    d.check("debug report names gtk") { app.window.visible_dialog.debug_info.include?("- gtk: 4.") }
    d.check("comments carry both headings") do
      app.window.visible_dialog.comments.include?("Back End") &&
        app.window.visible_dialog.comments.include?("The Name")
    end
  end

  d.step("screenshot the about dialog") do
    d.shot("03-about-dialog")
    app.window.visible_dialog&.close
  end

  d.step("the overview page starts empty") do
    d.check("empty state is visible") { app.overview_page.main_stack.visible_child == app.overview_page.empty_page }
    d.check("backups list is empty") { app.overview_page.backups.empty? }
  end

  d.step("the overview page shows a configured backup") do
    repo = Struct.new(:icon, :subtitle).new("drive-harddisk-symbolic", "/mnt/backup")
    config = Struct.new(
      :id,
      :title,
      :repo,
      :include,
    ).new(
      "1",
      "Home",
      repo,
      ["", "Pictures"],
    )
    app.overview_page.backups = [config]
  end

  d.step("the configured backup renders") do
    d.check("preferences page is visible") do
      app.overview_page.main_stack.visible_child == app.overview_page.preferences_page
    end
    d.check("one row was built") { !app.overview_page.main_backups.first_child.nil? }
  end

  d.step("screenshot the overview page") { d.shot("00-overview-page") }

  d.step("clearing the backups returns to the empty state") do
    app.overview_page.backups = []
    d.check("empty state is visible again") do
      app.overview_page.main_stack.visible_child == app.overview_page.empty_page
    end
  end

  d.step("swap in the leaf-widget gallery") { app.window.content = gallery }

  d.step("the leaf widgets render") do
    d.check("ok row carries the ok css class") do
      status_rows[0].status_icon.image.css_classes.include?("ok-icon")
    end
    d.check("warning row carries the warning css class") do
      status_rows[1].status_icon.image.css_classes.include?("warning-icon")
    end
    d.check("error row carries the error css class") do
      status_rows[3].status_icon.image.css_classes.include?("error-icon")
    end
    d.check("spinner row shows the spinner, not the image") do
      status_rows[4].status_icon.stack.visible_child == status_rows[4].status_icon.spinner
    end
    d.check("switching a level clears the old class") do
      status_rows[3].level = :ok
      status_rows[3].status_icon.image.css_classes.include?("ok-icon") &&
        !status_rows[3].status_icon.image.css_classes.include?("error-icon")
    end
    d.check("apply_status escapes and sets both lines") do
      status_rows[2].apply_status(
        title:    "Repo & Archives",
        subtitle: "a < b",
        graphic:  PikaBackup::StatusIcon::Graphic.warning_icon("dialog-warning-symbolic"),
      )
      status_rows[2].title == "Repo &amp; Archives" &&
        status_rows[2].subtitle == "a &lt; b" &&
        status_rows[2].status_icon.level == :warning
    end

    d.check("folder row starts empty") do
      folder_row.file.nil? && !folder_row.css_classes.include?("property")
    end
    d.check("setting a folder fills the subtitle") do
      folder_row.file = Gio::File.new_for_path(File.join(GLib.home_dir, "src"))
      folder_row.subtitle == "src" && folder_row.css_classes.include?("property")
    end
    d.check("reset clears it again") do
      folder_row.reset
      folder_row.subtitle.to_s.empty? && !folder_row.css_classes.include?("property")
    end

    d.check("the empty path tag reads Home") do
      PikaBackup::LocationTag.from_path("").label_text == "Home"
    end
    d.check("a missing path gets the warning icon") do
      PikaBackup::LocationTag.from_path("No/Such/Folder").icon.icon_name == "warning-symbolic"
    end
    d.check("an existing path gets the file's own icon") do
      PikaBackup::LocationTag.from_path("src").icon.icon_name != "warning-symbolic"
    end
    d.check("an exclude tag delegates to the rule") do
      rule = Struct.new(:description, :symbolic_icon).new("Caches", nil)
      PikaBackup::LocationTag.from_exclude(rule).label_text == "Caches"
    end
  end

  d.step("screenshot the gallery") { d.shot("04-leaf-widgets") }

  # The tag row sits below the gallery's viewport, and an unrealised widget has
  # no render node, so it gets the window to itself.
  d.step("show the location tags alone") do
    app.window.content = Adwaita::PreferencesPage.new.tap { |page| page.add(tag_group) }
  end

  d.step("screenshot the location tags") { d.shot("04b-location-tags") }

  d.step("the dialog page base class") do
    page = PikaBackup::DialogPage.new("Configure Backup").build
    page.add(Adwaita::ActionRow.new.tap { |row| row.title = "A row the subclass added" })
    page.subtitle = "A subtitle"

    d.check("title reaches the big label") { page.title_label.label == "Configure Backup" }
    d.check("subtitle shows when set") { page.subtitle_label.visible? }
    d.check("subtitle hides when cleared") do
      page.subtitle = ""
      !page.subtitle_label.visible?
    end
    d.check("can_close drives the header buttons") do
      page.can_close = false
      !page.header_bar.show_start_title_buttons? && !page.header_bar.show_end_title_buttons?
    end
    d.check("added children land in the content box") { !page.content_box.first_child.nil? }
    d.check("the dialog-page css class is set") { page.css_classes.include?("dialog-page") }

    app.window.content = page_host(page)
  end

  d.step("screenshot the dialog page") { d.shot("05-dialog-page") }

  d.step("the spinner page base class") do
    page = PikaBackup::SpinnerPage.new("Creating Backup Repository", "This may take a while").build

    d.check("title reaches the status page") { page.status_page.title == "Creating Backup Repository" }
    d.check("description reaches the status page") do
      page.status_page.description == "This may take a while"
    end
    d.check("a changed description follows") do
      page.description = "Still working"
      page.status_page.description == "Still working"
    end
    d.check("the page cannot be popped") { !page.can_pop? }
    d.check("the spinner is the status page paintable") { !page.status_page.paintable.nil? }

    app.window.content = page_host(page)
  end

  d.step("screenshot the spinner page") { d.shot("06-spinner-page") }
end
