# frozen_string_literal: true

# Drives the ported window, its two dialogs, and every leaf widget ported so
# far, then screenshots each of them.

require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require_relative "gtk_driver"
require "pika_backup"
require_relative "../lib/pika_backup/setup_types"

ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir

SHOTS = File.expand_path("../tmp/shots", __dir__)

application = PikaBackup::Application.new

# Every descendant of `widget` for which the block answers true. ActionRow
# wraps its prefixes and suffixes in its own internal boxes, so a child added
# through `add_prefix` is never `widget.first_child` itself.
def find_widgets(widget, found = [], &block)
  found.tap do
    found << widget if block.call(widget)
    child = widget.first_child
    while child
      find_widgets(child, found, &block)
      child = child.next_sibling
    end
  end
end

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

  d.step("the setup-wizard value types") do
    d.check("borg shorthand canonicalizes to ssh://") do
      location, error = PikaBackup::SetupRepoLocation.parse_url("user@host:path")
      error.nil? && location.to_s == "ssh://user@host/./path"
    end
    d.check("an explicit ssh:// URL round-trips") do
      location, error = PikaBackup::SetupRepoLocation.parse_url("ssh://user@host/path")
      error.nil? && location.remote? && location.to_s == "ssh://user@host/path"
    end
    d.check("a path with no scheme and no colon is rejected") do
      PikaBackup::SetupRepoLocation.parse_url("/local/path") == [nil, "Incomplete URL or borg syntax"]
    end
    d.check("an empty string is rejected the same way") do
      PikaBackup::SetupRepoLocation.parse_url("") == [nil, "Incomplete URL or borg syntax"]
    end
    d.check("a local file:// URL is local, not remote") do
      location, error = PikaBackup::SetupRepoLocation.parse_url("file:///tmp/repo")
      error.nil? && location.local? && location.value.is_a?(Gio::File)
    end
    d.check("a URL with no path is rejected") do
      PikaBackup::SetupRepoLocation.parse_url("ssh://host") ==
        [nil, "The remote location must have a specified path."]
    end

    d.check("extra borg args shell-split and round-trip") do
      args = PikaBackup::SetupCommandLineArgs.from_s(%(--foo bar --baz "qux quux"))
      args.to_a == ["--foo", "bar", "--baz", "qux quux"] &&
        args.to_s == %(--foo bar --baz qux\\ quux)
    end
    d.check("unmatched quoting falls back to no arguments rather than raising") do
      PikaBackup::SetupCommandLineArgs.from_s('"unterminated').empty?
    end
    d.check("NONE is the empty sentinel") { PikaBackup::SetupCommandLineArgs::NONE.empty? }
  end

  d.step("the UiUtils helpers") do
    d.check("rel_path strips $HOME") do
      PikaBackup::UiUtils.rel_path(File.join(GLib.home_dir, "src", "x")) == "src/x"
    end
    d.check("rel_path leaves a path outside $HOME alone") do
      PikaBackup::UiUtils.rel_path("/not/home/path") == "/not/home/path"
    end
    d.check("ellipsize_end passes short text through") do
      PikaBackup::UiUtils.ellipsize_end("hi", 5) == "hi"
    end
    d.check("ellipsize_end cuts and marks long text") do
      PikaBackup::UiUtils.ellipsize_end("hello world", 5) == "hell…"
    end
    d.check("Message.ellipsize_multiline passes short text through") do
      PikaBackup::Message.ellipsize_multiline("short") == "short"
    end
    d.check("Message.ellipsize_multiline keeps head and tail of long text") do
      long = "a" * 1000
      result = PikaBackup::Message.ellipsize_multiline(long)
      result.start_with?("a" * 300) && result.end_with?("a" * 200) && result.include?("…")
    end

    d.check("new_action_row_with_gicon builds a plain activatable row") do
      row = PikaBackup::UiUtils.new_action_row_with_gicon
      row.is_a?(Adwaita::ActionRow) && row.activatable? &&
        find_widgets(row) { |w| w.is_a?(Gtk::Image) && w.css_classes.include?("large-row-icon") }.empty?
    end
    d.check("new_action_row_with_gicon with an icon name adds a prefix image") do
      row = PikaBackup::UiUtils.new_action_row_with_gicon("edit-symbolic")
      icon = find_widgets(row) { |w| w.is_a?(Gtk::Image) && w.css_classes.include?("large-row-icon") }.first
      !icon.nil? && icon.icon_name == "edit-symbolic"
    end

    d.check("clear_listbox removes dynamic rows but keeps '-'-named structural ones") do
      box = Gtk::ListBox.new
      kept = Gtk::ListBoxRow.new.tap { |row| row.name = "-header" }
      removed = Gtk::ListBoxRow.new
      box.append(kept)
      box.append(removed)
      PikaBackup::UiUtils.clear_listbox(box)
      box.get_row_at_index(0).equal?(kept) && box.get_row_at_index(1).nil?
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
    d.check("Ctrl+? opens shortcuts") do
      app.app.get_accels_for_action("app.shortcuts") == ["<Control>question"]
    end
    d.check("the menu button's popover opens") do
      app.menu_button.active = true
      app.menu_button.active?
    end
    app.menu_button.active = false
  end

  # Closing the popover and shooting in the same tick raced the popover's own
  # close animation: the window had not been laid out again yet, so
  # Gtk::WidgetPaintable produced no render node at all. Giving the close its
  # own tick before the shot settles that.
  d.step("screenshot the main window") { d.shot("01-main-window") }

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

  # Regression check for a real bug this driver caught: launch_help rescued
  # GLib::Error, but Gio::AppInfo.launch_default_for_uri on a URI scheme with
  # no handler (certain in this sandbox, likely on any box with no help
  # viewer) raises Gio::IOError::NotSupported, which is not a GLib::Error
  # subclass — so the rescue never matched and activating Help crashed the
  # whole application. Fixed in application.rb to rescue StandardError too.
  d.step("the Help action fails in this sandbox and is caught, not crashed") do
    app.app.activate_action("help", nil)
  end

  d.step("the failure surfaced as the error dialog, not a crash") do
    d.check("a dialog is up") { !app.window.visible_dialog.nil? }
    d.check("it is an AdwAlertDialog, not the about or shortcuts dialog") do
      app.window.visible_dialog.is_a?(Adwaita::AlertDialog)
    end
    app.window.visible_dialog&.close
  end

  d.step("ErrorMessage without a window sends a notification instead") do
    @notified = nil
    fake_app = Struct.new(:sent) do
      def send_notification(_id, notification) = (self.sent = notification)
    end.new(nil)
    # An object answering neither mapped? nor active? takes the
    # notification branch of Message#show_transient_for, exactly as a
    # background operation with no window in front would.
    PikaBackup::ErrorMessage.message(PikaBackup::Message.short("Something failed"))
                             .show_transient_for(Object.new, fake_app) { |response| @notified = response }
    d.check("a notification was sent") { !fake_app.sent.nil? }
    d.check("on_response still fired with close") { @notified == "close" }
  end

  d.step("ErrorMessage.user_canceled short-circuits to nothing") do
    canceled = PikaBackup::ErrorMessage.user_canceled
    d.check("it reports canceled") { canceled.user_canceled? }
    d.check("its message text is empty") { canceled.message_text == "" }
    d.check("show_transient_for is a no-op (no dialog, no raise)") do
      canceled.show_transient_for(app.window, app.app) { |_r| raise "should not be called" }
      true
    end
  end

  d.step("the confirmation dialog opens with the caller's text") do
    @confirmed = nil
    PikaBackup::UiUtils.confirmation_dialog(
      app.window, "Remove backup?", "This cannot be undone.", "Cancel", "Remove",
      destructive: true,
    ) { |ok| @confirmed = ok }
  end

  d.step("it carries the right heading, body, and destructive accept button") do
    dialog = app.window.visible_dialog
    d.check("it is showing") { !dialog.nil? }
    d.check("heading is the title") { dialog.heading == "Remove backup?" }
    d.check("body is the message") { dialog.body == "This cannot be undone." }
    d.check("accept is labelled Remove") { dialog.get_response_label("accept") == "Remove" }
    d.check("cancel is labelled Cancel") { dialog.get_response_label("cancel") == "Cancel" }
    d.check("accept is styled destructive") do
      dialog.get_response_appearance("accept") == :destructive
    end
    d.check("cancel is the close and default response (destructive default)") do
      dialog.close_response == "cancel" && dialog.default_response == "cancel"
    end
    d.shot("03b-confirmation-dialog")
    dialog.close
  end

  d.step("closing without choosing never calls the accept block") do
    d.check("the block was never run") { @confirmed.nil? }
    d.check("the dialog is gone") { app.window.visible_dialog.nil? }
  end

  d.step("a non-destructive confirmation defaults to accept") do
    PikaBackup::UiUtils.confirmation_dialog(
      app.window, "Check archives?", "This may take a while.", "Cancel", "Check",
    ) { |ok| @confirmed = ok }
  end

  d.step("its default response is accept, not cancel") do
    dialog = app.window.visible_dialog
    d.check("default is accept") { dialog.default_response == "accept" }
    d.check("accept is not styled destructive") do
      dialog.get_response_appearance("accept") != :destructive
    end
    dialog.close
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
    d.check("the row shows the never-run status") do
      row = app.overview_page.main_backups.first_child
      row.status.title == PikaBackup::OverviewRow::NEVER_RUN_TITLE &&
        row.status.subtitle == PikaBackup::OverviewRow::NEVER_RUN_SUBTITLE
    end
    d.check("the row shows the no-schedule status") do
      app.overview_page.main_backups.first_child.schedule_status.title ==
        PikaBackup::OverviewRow::NO_SCHEDULE_TITLE
    end
    d.check("activating the location row does not crash (no backend wired yet)") do
      app.overview_page.main_backups.first_child.location_row.activate
      true
    end
    d.check("activating the schedule-status row does not crash") do
      app.overview_page.main_backups.first_child.schedule_status.activate
      true
    end
    d.check("the add-backup header button does not crash with no handler") do
      app.overview_page.add_backup_button.activate
      true
    end
    d.check("overview-row carries its css class") do
      app.overview_page.main_backups.first_child.css_classes.include?("overview-row")
    end
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

  d.step("the encryption settings widget starts unencrypted") do
    @valid_changes = []
    @encryption = PikaBackup::EncryptionSettings.new(
      on_valid_changed: ->(v) { @valid_changes << v },
    ).build

    d.check("starts unencrypted") { !@encryption.encrypted }
    d.check("an empty, unencrypted widget is valid") { @encryption.valid }
    d.check("description text is set") { !@encryption.description.empty? }
    d.check("the password fields are hidden") { !@encryption.revealer.reveal_child? }

    app.window.content = page_host(PikaBackup::DialogPage.new("Encryption").tap do |page|
      page.build
      page.add(@encryption)
    end.build)
  end

  d.step("screenshot the encryption settings, unencrypted") { d.shot("07-encryption-unencrypted") }

  d.step("turning the switch on asks for confirmation first") do
    @encryption.encrypted_switch.active = true

    d.check("a confirmation dialog is up") { !app.window.visible_dialog.nil? }
    d.check("it is the encryption confirmation dialog") do
      app.window.visible_dialog.is_a?(Adwaita::AlertDialog) &&
        app.window.visible_dialog.heading == "Use Encryption?"
    end
    d.check("encrypted has not flipped yet (waiting on the dialog)") { !@encryption.encrypted }
  end

  d.step("screenshot the confirmation dialog") { d.shot("08-encryption-confirm") }

  d.step("canceling leaves encryption off") do
    # AlertDialog has no programmatic "choose this response" call in the Ruby
    # bindings (no `response`/`activate_response` method) — only
    # `choose`/`choose_finish`, which the widget itself drives from a real
    # button press. `Gtk::Button#activate` (the generic widget-activate
    # signal) does not trigger it here; emitting the button's own "clicked"
    # signal does, so that is what exercises `choose`'s callback for real,
    # the same way a click would.
    cancel_button = find_widgets(app.window.visible_dialog) { |w| w.is_a?(Gtk::Button) && w.label == "Cancel" }.first
    cancel_button.signal_emit("clicked")

    d.check("the switch snapped back off") { !@encryption.encrypted_switch.active? }
    d.check("encrypted is still false") { !@encryption.encrypted }
    d.check("still valid (unencrypted is always valid)") { @encryption.valid }
  end

  d.step("turning the switch on again and accepting enables it") do
    @encryption.encrypted_switch.active = true
  end

  d.step("accepting the warning turns encryption on") do
    use_button = find_widgets(app.window.visible_dialog) { |w| w.is_a?(Gtk::Button) && w.label == "Use Encryption" }.first
    use_button.signal_emit("clicked")

    d.check("encrypted is now true") { @encryption.encrypted }
    d.check("the password fields reveal") { @encryption.revealer.reveal_child? }
    d.check("empty password is invalid") { !@encryption.valid }
    d.check("valid flipped false (was true when unencrypted)") { @valid_changes.last == false }
  end

  d.step("screenshot the encryption settings, encrypted but empty") { d.shot("09-encryption-empty") }

  d.step("typing a weak password scores it low and stays invalid") do
    @encryption.password_entry.text = "password"

    d.check("validation names the common password") do
      @encryption.validation_label.label == "This is a very commonly used password"
    end
    d.check("still invalid (no confirmation yet)") { !@encryption.valid }
    valid, error = @encryption.validated_password
    d.check("validated_password reports the missing confirmation") do
      valid.nil? && error == "The passwords do not match"
    end
  end

  d.step("a mismatched confirmation is flagged on the field") do
    @encryption.password_confirm_entry.text = "something else"

    d.check("confirm entry carries the error class") do
      @encryption.password_confirm_entry.css_classes.include?("error")
    end
    d.check("validation reports the mismatch") { @encryption.validation_label.label == "Passwords do not match" }
    d.check("still invalid") { !@encryption.valid }
  end

  d.step("matching confirmation with a strong password becomes valid") do
    @encryption.password_entry.text = "Tr0ub4dor&3xyzzy!"
    @encryption.password_confirm_entry.text = "Tr0ub4dor&3xyzzy!"

    d.check("confirm entry's error class clears") do
      !@encryption.password_confirm_entry.css_classes.include?("error")
    end
    d.check("now valid") { @encryption.valid }
    d.check("valid flipped true") { @valid_changes.last == true }
    valid, error = @encryption.validated_password
    d.check("validated_password returns the password with no error") do
      valid == "Tr0ub4dor&3xyzzy!" && error.nil?
    end
  end

  d.step("screenshot the encryption settings, valid and strong") { d.shot("10-encryption-valid") }

  d.step("reset blanks both fields and restores the given switch state") do
    @encryption.reset(false)

    d.check("switch is off") { !@encryption.encrypted_switch.active? }
    d.check("password entry is blank") { @encryption.password_entry.text.to_s.empty? }
    d.check("confirm entry is blank") { @encryption.password_confirm_entry.text.to_s.empty? }
    d.check("valid again (unencrypted)") { @encryption.valid }
  end
end
