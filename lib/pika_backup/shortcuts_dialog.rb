# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # ShortcutsDialog lists the app's keyboard shortcuts.
  #
  # Ported from data/resources/shortcuts-dialog.ui: one AdwShortcutsSection,
  # "General", with five items. Upstream gives two of them an accelerator
  # directly and three an action name, letting AdwShortcutsItem look the
  # accelerator up from the action's own accel — so the list stays correct when
  # a binding changes.
  class ShortcutsDialog < Adwaita::ShortcutsDialog
    SECTION_TITLE = "General"

    # Each item is either [title, accelerator] or [title, action: name].
    ITEMS = [
      ["Set Up New Backup", {accelerator: "<Ctrl>N"}],
      ["Show Keyboard Shortcuts", {action: "app.shortcuts"}],
      ["Quit", {action: "app.quit"}],
      ["Back", {accelerator: "<alt>Left"}],
      ["Open Menu", {accelerator: "F10"}],
    ].freeze

    def build
      tap { add(section) }
    end

    def section
      @section ||= Adwaita::ShortcutsSection.new.tap do |section|
        section.title = SECTION_TITLE
        ITEMS.each { |title, source| section.add(item(title, source)) }
      end
    end

    private

    # AdwShortcutsItem takes its title and accelerator positionally — a
    # no-argument `new` is rejected, and so is a nil accelerator. An
    # action-backed item therefore starts with an empty accelerator and gets
    # its action name set afterwards.
      def item(title, source)
        Adwaita::ShortcutsItem.new(title, source[:accelerator].to_s).tap do |shortcut|
          if source[:action]
            shortcut.action_name = source[:action]
          end
        end
      end
  end
end
