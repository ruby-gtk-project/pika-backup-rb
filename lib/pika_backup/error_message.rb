# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # Message is the one shape every user-facing error or confirmation prompt
  # in the app takes: a primary line, an optional detail, and how to show it
  # — as a modal AdwAlertDialog when a window is in front of the user, or as
  # a desktop notification when it is not.
  #
  # Ported from pika-backup/src/error.rs's `Message` and `Error`. Upstream's
  # `Error` enum also carries borg-specific error variants and the `Combined`
  # type that merges them with borg's own error type; none of that backend is
  # ported yet, so this keeps only the two variants that are pure UI:
  # `Message` and `UserCanceled`. The borg-error slot on `Message` is kept as
  # a plain attribute (`borg_error`) rather than typed, so a future borg port
  # can set it without this file changing.
  #
  # Upstream's `show`/`show_transient_for` are `async fn`s that await a
  # GTK4 async dialog. The Ruby bindings have no async/await, so this takes
  # the callback shape `Adwaita::AlertDialog#choose` actually offers: the
  # block runs once a response is chosen, exactly where upstream's `.await`
  # would resume.
  class Message
    MAX_ELLIPSIS_LEN = 510
    HEAD_LEN = 300
    TAIL_LEN = 200

    attr_accessor :markup
    attr_reader :text, :secondary_text, :notification_id, :borg_error

    def initialize(text, secondary_text = nil, notification_id: nil, borg_error: nil)
      @text = text.to_s
      @secondary_text = secondary_text&.to_s
      @notification_id = notification_id&.to_s
      @borg_error = borg_error
      @markup = false
    end

    def self.with_borg(text, secondary_text, borg_error)
      new(text, secondary_text, borg_error: borg_error)
    end

    def self.with_notification_id(text, secondary_text, notification_id)
      new(text, secondary_text, notification_id: notification_id)
    end

    def self.short(text) = new(text, nil)

    # Shows the message against the given window, picking the dialog or the
    # notification path exactly as upstream's `show_transient_for` does:
    # a dialog when a toplevel is mapped and active, a notification
    # otherwise. `app` is the Gio::Application the notification goes through.
    def show_transient_for(window, app, &on_response)
      primary = self.class.ellipsize_multiline(text)
      secondary = self.class.ellipsize_multiline(secondary_text.to_s)

      if window_active?(window)
        present_dialog(window, primary, secondary, &on_response)
      else
        send_notification(app, primary, secondary)
        on_response&.call("close")
      end
    end

    def to_s
      if secondary_text
        "#{text}\n#{secondary_text}"
      else
        text
      end
    end

    def self.ellipsize_multiline(text)
      chars = text.to_s.chars

      if chars.length > MAX_ELLIPSIS_LEN
        "#{chars.first(HEAD_LEN).join}\n…\n#{chars.last(TAIL_LEN).join}"
      else
        text.to_s
      end
    end

    private

    def window_active?(window)
      window.respond_to?(:mapped?) && window.mapped? &&
        window.respond_to?(:active?) && window.active?
    end

    def present_dialog(window, primary, secondary, &on_response)
      Adwaita::AlertDialog.new(primary, secondary).tap do |dialog|
        dialog.prefer_wide_layout = true
        dialog.body_use_markup = markup
        dialog.add_response("close", "_Close")
        dialog.close_response = "close"
        dialog.default_response = "close"

        dialog.choose(window, nil) do |_source, result|
          response = dialog.choose_finish(result)
          on_response&.call(response)
        end
      end
    end

    def send_notification(app, primary, secondary)
      title, body =
        if secondary.empty?
          ["Pika Backup", primary]
        else
          [primary, secondary]
        end

      body = strip_markup(body) if markup

      Gio::Notification.new(title).tap do |notification|
        notification.set_body(body)
        app.send_notification(notification_id, notification)
      end
    end

    # g_markup_parse's strip-tags-only behaviour, approximated: the
    # notification body cannot render Pango markup, so any tags are dropped.
    def strip_markup(body) = body.gsub(/<[^>]*>/, "")
  end

  # The port's stand-in for upstream's `Error` enum: either a `Message` to
  # show, or the "the user dismissed a dialog" sentinel that upstream's
  # `UserCanceled` variant is — carried as a symbol here rather than a case
  # class, since there are no fields to attach to it.
  class ErrorMessage < StandardError
    USER_CANCELED = :user_canceled

    attr_reader :message_obj

    def self.message(msg) = new(msg)

    def self.user_canceled = new(USER_CANCELED)

    def initialize(message_obj)
      @message_obj = message_obj
      super(message_obj.is_a?(Message) ? message_obj.to_s : "Canceled")
    end

    def user_canceled? = message_obj == USER_CANCELED

    def show_transient_for(window, app, &on_response)
      message_obj.show_transient_for(window, app, &on_response) unless user_canceled?
    end

    def message_text
      user_canceled? ? "" : message_obj.text
    end

    def message_secondary_text
      user_canceled? ? nil : message_obj.secondary_text
    end
  end

  # Handler is upstream's `error::Handler`: the one place a background
  # operation's result turns into either nothing (success, or a cancel the
  # user already saw coming) or a dialog/notification. Upstream spawns the
  # given future on the main context and awaits it; since there is nothing
  # to await here, `run` takes a block that is called immediately and must
  # return either `nil`/`:ok` on success or a raised/returned `ErrorMessage`
  # on failure.
  class Handler
    def self.handle(result, window, app)
      new(window, app).handle(result)
    end

    def initialize(window, app)
      @window = window
      @app = app
    end

    # `result` is an ErrorMessage, a plain StandardError, or nil/anything
    # else standing in for success — mirroring upstream's `Result<()>`.
    def handle(result)
      case result
      when ErrorMessage
        result.show_transient_for(@window, @app) unless result.user_canceled?
      when StandardError
        ErrorMessage.message(Message.short(result.message)).show_transient_for(@window, @app)
      end
    end

    def run
      handle(yield)
    rescue ErrorMessage => e
      handle(e)
    end
  end
end
