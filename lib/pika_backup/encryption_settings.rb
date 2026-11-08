# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # EncryptionSettings is the switch-plus-password-entries widget the setup
  # wizard's encryption page embeds: a toggle for whether a backup is
  # encrypted, and, while it is, a password entry, a confirmation entry, a
  # strength meter and feedback label underneath it.
  #
  # Ported from pika-backup/src/widget/encryption_settings.rs and
  # encryption_settings.ui. Upstream subclasses GtkBox with GObject
  # properties (`encrypted`, `description`, `valid`) and a `notify::valid`
  # signal the setup wizard's pages bind their "Next" button's sensitivity
  # to. The Ruby bindings cannot add GObject properties to a Ruby subclass
  # (see StatusRow), so `encrypted` and `valid` are plain accessors here, and
  # `on_valid_changed` is a constructor callback the way OverviewRow takes
  # its callbacks, fired whenever `valid` actually flips.
  #
  # Upstream scores the password with the `zxcvbn` crate. No Ruby binding of
  # zxcvbn is available in this project's dev shell (`gem list -r zxcvbn`
  # shows it only on rubygems.org, and `require "zxcvbn"` fails inside
  # `nix develop` because the shell's gem set is closed, not
  # network-installable), so `score_password` estimates strength itself: a
  # brute-force guess count from the character pool and length, the same
  # `guesses_log10` buckets upstream's score derives from, with a small set
  # of pattern and common-password checks standing in for zxcvbn's
  # dictionary and sequence detectors. It is a plainer estimate than
  # zxcvbn's, not a stub — every branch computes and returns a real result.
  #
  # `common::config::Password` is not ported (the `config` module it lives in
  # does not exist in this port yet), so `validated_password` returns the
  # plain password string instead of wrapping it.
  class EncryptionSettings < Gtk::Box
    DESCRIPTION = "The data stored in encrypted backups is password " \
      "protected. If encryption is used, the password is required for " \
      "accessing your backups."

    COMMON_PASSWORDS = %w[
      password 123456 123456789 qwerty 12345678 111111 1234567890 1234567
      password1 12345 1234 123123 abc123 letmein welcome monkey dragon
      iloveyou admin qwertyuiop
    ].freeze

    KEYBOARD_ROWS = %w[qwertyuiop asdfghjkl zxcvbnm 1234567890].freeze

    def initialize(on_valid_changed: nil)
      super(:vertical, 0)
      add_css_class("encryption-settings")
      @encrypted = false
      @valid = false
      @on_valid_changed = on_valid_changed
    end

    def build
      tap do
        append(switch_group)
        append(revealer)

        switch_group.tap { |group| group.add(encrypted_switch) }

        encrypted_switch.tap do |row|
          row.signal_connect("notify::active") { on_switch_active }
        end

        revealer.tap do |r|
          r.reveal_child = @encrypted
          r.child = password_group
        end

        password_group.tap do |group|
          group.add(password_entry)
          group.add(password_confirm_entry)
          group.add(password_quality_bar)
          group.add(validation_label)
        end

        password_entry.tap do |row|
          row.signal_connect("changed") { score_password }
        end

        password_confirm_entry.tap do |row|
          row.signal_connect("changed") { score_password }
        end

        score_password
      end
    end

    attr_reader :encrypted, :valid

    def encrypted=(encrypted)
      @encrypted = !!encrypted
      encrypted_switch.active = @encrypted
      revealer.reveal_child = @encrypted
    end

    def description = DESCRIPTION

    # Upstream's `reset(encrypted)`: puts the switch in the given state and
    # blanks both entries.
    def reset(encrypted)
      self.encrypted = encrypted
      password_entry.text = ""
      password_confirm_entry.text = ""
      score_password
    end

    # Returns `[password, nil]` on success and `[nil, error_message]` on
    # failure — the two halves of upstream's `Result<Option<Password>>`,
    # following the convention `SetupRepoLocation.parse_url` already uses in
    # this port.
    def validated_password
      if @encrypted
        password = password_entry.text.to_s

        if password.empty?
          [nil, "To use encryption a password must be provided"]
        elsif password != password_confirm_entry.text.to_s
          [nil, "The passwords do not match"]
        else
          [password, nil]
        end
      else
        [nil, nil]
      end
    end

    def switch_group = @switch_group ||= Adwaita::PreferencesGroup.new

    def encrypted_switch
      @encrypted_switch ||= Adwaita::SwitchRow.new.tap do |row|
        row.title = "Use Encryption"
        row.active = false
      end
    end

    def revealer = @revealer ||= Gtk::Revealer.new

    def password_group = @password_group ||= Adwaita::PreferencesGroup.new

    def password_entry
      @password_entry ||= Adwaita::PasswordEntryRow.new.tap do |row|
        row.title = "Encryption Password"
        row.activates_default = true
      end
    end

    def password_confirm_entry
      @password_confirm_entry ||= Adwaita::PasswordEntryRow.new.tap do |row|
        row.title = "Repeat Password"
        row.activates_default = true
      end
    end

    def password_quality_bar
      @password_quality_bar ||= Gtk::LevelBar.new.tap do |bar|
        bar.add_css_class("password-quality")
        bar.margin_top = 12
        bar.mode = :continuous
        bar.max_value = 7
        bar.add_offset_value("low", 3.0)
        bar.add_offset_value("high", 5.0)
        bar.add_offset_value("full", 7.0)
      end
    end

    def validation_label
      @validation_label ||= Gtk::Label.new.tap do |label|
        label.margin_top = 12
        label.single_line_mode = true
        label.ellipsize = :end
        label.justify = :center
        label.add_css_class("dim-label")
      end
    end

    private

      def on_switch_active
        switch_encrypted = encrypted_switch.active?

        if switch_encrypted == @encrypted
          update_valid
        else
          if switch_encrypted
            confirm_encryption
          else
            self.encrypted = false
            password_entry.text = ""
            password_confirm_entry.text = ""
            score_password
          end

          update_valid
        end
      end

      def confirm_encryption
        dialog = Adwaita::AlertDialog.new(
          "Use Encryption?",
          "Losing access to the encryption password will lead to a complete loss of all backed up data",
        )
        dialog.add_response("close", "Cancel")
        dialog.add_response("encrypt", "Use Encryption")
        dialog.set_response_appearance("encrypt", :suggested)

        dialog.choose(root, nil) do |_source, result|
          accept_encryption_choice(dialog, result)
        end
      end

      def accept_encryption_choice(dialog, result)
        if dialog.choose_finish(result) == "encrypt"
          self.encrypted = true
        else
          encrypted_switch.active = false
        end

        score_password
        update_valid
      end

      def update_valid
        now_valid = validated_password[1].nil?

        if now_valid != @valid
          @valid = now_valid
          @on_valid_changed&.call(@valid)
        end
      end

      def score_password
        password = password_entry.text.to_s
        confirm = password_confirm_entry.text.to_s

        score = score_for(password)
        mismatch = !confirm.empty? && password != confirm

        validation_label.label = validation_text(password, score, mismatch)
        password_quality_bar.value = score

        mismatch ? password_confirm_entry.add_css_class("error") : password_confirm_entry.remove_css_class("error")

        update_valid
      end

      def validation_text(password, score, mismatch)
        if password.empty?
          "Enter a password"
        elsif mismatch
          "Passwords do not match"
        elsif score < 7
          warning_for(password) || "Add a few more words"
        else
          "This looks like a strong password"
        end
      end

      # The bucket boundaries upstream derives from zxcvbn's
      # `guesses_log10`: <3 a second, <6 seconds, <8 minutes, <10 hours, <12
      # days, <14 months/years, otherwise centuries.
      def score_for(password)
        if password.empty?
          0
        else
          guesses_log10 = guesses_log10_for(password)

          if guesses_log10 < 3
            1
          elsif guesses_log10 < 6
            2
          elsif guesses_log10 < 8
            3
          elsif guesses_log10 < 10
            4
          elsif guesses_log10 < 12
            5
          elsif guesses_log10 < 14
            6
          else
            7
          end
        end
      end

      def guesses_log10_for(password)
        if COMMON_PASSWORDS.include?(password.downcase)
          0.5
        elsif repeated_character?(password)
          1.0
        elsif sequential?(password)
          1.0
        elsif keyboard_run?(password)
          1.5
        else
          password.length * Math.log10(character_pool_size(password))
        end
      end

      def character_pool_size(password)
        classes = [[/[a-z]/, 26], [/[A-Z]/, 26], [/[0-9]/, 10], [/[^a-zA-Z0-9]/, 33]]
        pool = classes.sum { |pattern, size| password.match?(pattern) ? size : 0 }
        pool.zero? ? 1 : pool
      end

      def repeated_character?(password) = password.match?(/\A(.)\1*\z/)

      def sequential?(password)
        chars = password.downcase.chars.map { |c| c.ord }
        ascending = chars.each_cons(2).all? { |a, b| b - a == 1 }
        descending = chars.each_cons(2).all? { |a, b| a - b == 1 }
        chars.length > 2 && (ascending || descending)
      end

      def keyboard_run?(password)
        lower = password.downcase
        KEYBOARD_ROWS.any? { |row| row.include?(lower) || row.reverse.include?(lower) }
      end

      # Checked in the same priority `guesses_log10_for` scores by: a
      # password that is both, say, a common password and a single short
      # word (e.g. "password" itself) should be named for the stronger
      # reason, not the weaker one.
      def warning_for(password)
        if COMMON_PASSWORDS.include?(password.downcase)
          "This is a very commonly used password"
        elsif repeated_character?(password)
          "Avoid repetitions like “aaa” or “abcabc”"
        elsif sequential?(password)
          "Avoid sequences like “abc” or “6543”"
        elsif keyboard_run?(password)
          "Avoid keyboard patterns"
        elsif password.match?(/\A[a-zA-Z]+\z/) && password.length < 10
          "A single word is easy to guess"
        else
          nil
        end
      end
  end
end
