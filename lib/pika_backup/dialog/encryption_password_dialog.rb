# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # EncryptionPasswordDialog asks for a repository's encryption password when
  # it is needed mid-operation — for example after the keyring lookup for a
  # saved password has failed.
  #
  # Ported from pika-backup/src/widget/dialog/encryption_password.rs and
  # encryption_password.ui: an AdwAlertDialog with a single GtkPasswordEntry
  # as its extra child, "Cancel" and the suggested "Continue" as its two
  # responses, and "apply" as both the default and Enter's target.
  #
  # Upstream's `present_with` is an `async fn` that takes the repository and
  # returns `Option<config::Password>` once the dialog is answered. The Ruby
  # bindings have no async/await, so this takes the callback shape
  # `Adwaita::AlertDialog#choose` actually offers — the same shape
  # ErrorMessage's `Message#present_dialog` already uses — and the block runs
  # once a response is chosen, exactly where upstream's `.await` would
  # resume. `config::Repository` and `config::Password` are not ported, so
  # `present_with` takes the repository's location as a plain string and the
  # callback is handed the entered password as a plain string (or `nil` on
  # cancel) rather than a `config::Password` wrapper.
  class EncryptionPasswordDialog < Adwaita::AlertDialog
    HEADING = "Encryption Password Required"

    def initialize
      super()
      self.heading = HEADING
      self.default_response = "apply"
      add_response("cancel", "_Cancel")
      add_response("apply", "Co_ntinue")
      set_response_appearance("apply", :suggested)
      self.extra_child = password_entry
    end

    # `repo_location` is what upstream's `repo.location()` renders — the
    # string this port's SetupRepoLocation#to_s already produces for a
    # repository. `keyring_error`, when given, is appended as a second
    # paragraph exactly as upstream appends it.
    def present_with(parent, repo_location:, purpose:, keyring_error: nil, &on_password)
      self.body = body_text(repo_location, purpose, keyring_error)
      password_entry.text = ""

      choose(parent, nil) do |_source, result|
        response = choose_finish(result)
        on_password&.call(response == "apply" ? password_entry.text : nil)
      end

      password_entry.grab_focus
    end

    def password_entry
      @password_entry ||= Gtk::PasswordEntry.new.tap do |entry|
        entry.placeholder_text = "Password"
        entry.halign = :center
        entry.width_request = 260
        entry.margin_top = 6
        entry.activates_default = true
        entry.show_peek_icon = true
      end
    end

    private

      def body_text(repo_location, purpose, keyring_error)
        text = "The operation “#{purpose}” requires the encryption password " \
               "of the repository on “#{repo_location}”."
        text += "\n\n#{keyring_error}" if keyring_error
        text
      end
  end
end
