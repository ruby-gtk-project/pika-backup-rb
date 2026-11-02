# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # FolderRow is the row that picks a folder: activating it opens a folder
  # chooser, and the chosen folder's name becomes the row's subtitle.
  #
  # Ported from pika-backup/src/widget/folder_row.rs and folder_row.ui.
  # Upstream subclasses AdwActionRow, marks it activatable with a button
  # accessible role, adds a `folder-open-symbolic` suffix, and overrides the
  # row's `activate` vfunc to run the folder chooser. The Ruby bindings cannot
  # override a vfunc on a Ruby subclass, so this connects to the row's
  # `activated` signal, which AdwActionRow emits for exactly that case.
  class FolderRow < Adwaita::ActionRow
    CHOOSER_TITLE = "Backup Location"
    SUFFIX_ICON = "folder-open-symbolic"

    # Upstream adds `property` while a folder is set, which styles the subtitle
    # as a value rather than as descriptive text.
    SET_CSS_CLASS = "property"

    def initialize
      super()
      self.activatable = true
      self.accessible_role = :button
    end

    def build
      tap do
        add_suffix(suffix_icon)

        signal_connect("activated") { choose_folder }
      end
    end

    attr_reader :file

    def file=(file)
      @file = file

      if file
        add_css_class(SET_CSS_CLASS)
        self.subtitle = file.basename.to_s
      else
        remove_css_class(SET_CSS_CLASS)
        self.subtitle = ""
      end
    end

    def reset = self.file = nil

    def suffix_icon = @suffix_icon ||= Gtk::Image.new(icon_name: SUFFIX_ICON)

    private

    # Upstream preselects the folder already chosen, or the user's home when
    # there is none.
      def choose_folder
        folder_dialog.tap do |dialog|
          dialog.initial_folder = @file || Gio::File.new_for_path(GLib.home_dir)

          dialog.select_folder(root, nil) do |_source, result|
            accept_folder(dialog, result)
          end
        end
      end

      def folder_dialog
        Gtk::FileDialog.new.tap do |dialog|
          dialog.title = CHOOSER_TITLE
          dialog.modal = true
        end
      end

    # Dismissing the chooser is not an error upstream either: the row simply
    # keeps the folder it already had.
      def accept_folder(dialog, result)
        self.file = dialog.select_folder_finish(result)
      rescue Gtk::DialogError::Dismissed, Gtk::DialogError::Cancelled
        nil
      end
  end
end
