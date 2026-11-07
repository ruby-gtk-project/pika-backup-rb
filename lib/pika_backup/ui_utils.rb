# frozen_string_literal: true

require "adwaita"
require_relative "error_message"

module PikaBackup
  # The helpers detail/dialog widgets share: the confirmation dialog, the
  # toast/notification path, and a few small string and GListModel helpers.
  #
  # Ported from pika-backup/src/utils.rs. That file also carries borg
  # process plumbing (`spawn_thread`, `AsyncErr`), the config-id lookup
  # traits (`LookupActiveConfigId`, `SummarizeOperations`), the background
  # portal request (`background_permission`), and `show_borg_question` —
  # all of which need the borg/config backend this port has not reached
  # yet, so none of that is here. What is ported is everything that is pure
  # UI or pure string/path logic: `rel_path`, `ellipsize_end`, `show_notice`,
  # the `ConfirmationDialog` class and its `confirmation_dialog` shorthand,
  # `clear` (named `clear_listbox` here since `clear` collides with too
  # much), and `new_action_row_with_gicon`.
  module UiUtils
    # utils.rs's `rel_path`: strips $HOME off the front of a path, when the
    # path is under it.
    def self.rel_path(path)
      home = GLib.home_dir.to_s.chomp("/")
      path = path.to_s

      if home.length.positive? && path.start_with?("#{home}/")
        path[(home.length + 1)..]
      else
        path
      end
    end

    # utils.rs's `ellipsize_end`: truncates to `max_len` characters,
    # replacing the last one with an ellipsis when it had to cut anything.
    def self.ellipsize_end(text, max_len)
      text = text.to_s

      if text.length <= max_len
        text
      else
        "#{text[0, [max_len, 1].max - 1]}…"
      end
    end

    # utils.rs's `show_notice`: an un-timed toast on the window, plus a
    # desktop notification when the window is not currently mapped.
    def self.show_notice(message, window, app)
      window.add_toast(Adwaita::Toast.new(message.to_s)) if window.respond_to?(:add_toast)

      unless window.respond_to?(:mapped?) && window.mapped?
        Gio::Notification.new("Pika Backup").tap do |notification|
          notification.set_body(message.to_s)
          app.send_notification(nil, notification)
        end
      end
    end

    # utils.rs's `confirmation_dialog` free function: the common case of
    # `ConfirmationDialog.new(...).ask(widget)`, but callback-shaped since
    # there is no async/await here. The block is called with `true` on
    # acceptance and not at all when the user cancels — the two outcomes
    # upstream's `Result<()>` carries as `Ok(())` and `Err(UserCanceled)`.
    def self.confirmation_dialog(window, title, message, cancel, accept, destructive: false, &on_accept)
      ConfirmationDialog.new(title, message, cancel, accept, destructive: destructive).ask(window, &on_accept)
    end

    # utils.rs's `clear`: empties a GtkListBox, except rows whose widget
    # name starts with "-" (upstream's marker for a row that is part of the
    # box's own static structure rather than dynamic content).
    def self.clear_listbox(listbox)
      index = 0

      while (row = listbox.get_row_at_index(index))
        if row.name.to_s.start_with?("-")
          index += 1
        else
          listbox.remove(row)
        end
      end
    end

    # utils.rs's `new_action_row_with_gicon`: an activatable AdwActionRow
    # with an optional leading icon in the "large-row-icon" CSS class.
    def self.new_action_row_with_gicon(icon_name = nil)
      Adwaita::ActionRow.new.tap do |row|
        row.activatable = true

        if icon_name
          row.add_prefix(
            Gtk::Image.new.tap do |image|
              image.icon_name = icon_name
              image.add_css_class("large-row-icon")
            end,
          )
        end
      end
    end

    # Ported from utils.rs's `ConfirmationDialog`. `ask` takes the place of
    # upstream's `async fn ask`: it presents the dialog and calls the block
    # with `true` when the user picked "accept", calling it not at all on
    # cancel (matching `Err(Error::UserCanceled)` being swallowed by every
    # caller that just wants to know whether to proceed).
    class ConfirmationDialog
      def initialize(title, message, cancel, accept, destructive: false)
        @title = title.to_s
        @message = message.to_s
        @cancel = cancel.to_s
        @accept = accept.to_s
        @destructive = destructive
      end

      def ask(window, &on_accept)
        dialog.tap do |d|
          d.choose(window, nil) do |_source, result|
            on_accept&.call(true) if d.choose_finish(result) == "accept"
          end
        end
      end

      private

      def dialog
        Adwaita::AlertDialog.new(@title, @message).tap do |d|
          d.prefer_wide_layout = true
          d.add_response("cancel", @cancel)
          d.add_response("accept", @accept)
          d.set_response_appearance("accept", :destructive) if @destructive
          d.close_response = "cancel"
          d.default_response = @destructive ? "cancel" : "accept"
        end
      end
    end
  end
end
