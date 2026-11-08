# frozen_string_literal: true

module PikaBackup
  # BackupNote names the two per-backup desktop notification ids the app
  # withdraws once a backup is dismissed or a new run starts.
  #
  # Ported from pika-backup/src/utils/notification.rs's `BackupNote` enum and
  # its `Display` impl. `config::ConfigId` is not ported yet, so each
  # constructor takes the plain id string a `ConfigId` would format itself
  # as.
  class BackupNote
    attr_reader :config_id

    def self.warnings(config_id) = new(:warnings, config_id)

    def self.failed(config_id) = new(:failed, config_id)

    def initialize(kind, config_id)
      @kind = kind
      @config_id = config_id.to_s
    end

    def warnings? = @kind == :warnings

    def failed? = @kind == :failed

    def to_s
      case @kind
      when :warnings
        "backup-warnings-#{config_id}"
      when :failed
        "backup-failed-#{config_id}"
      end
    end

    def ==(other) = other.is_a?(BackupNote) && other.to_s == to_s
  end
end
