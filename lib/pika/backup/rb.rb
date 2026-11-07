# frozen_string_literal: true

require_relative "rb/version"

# The gem's entry point under its canonical `pika/backup/rb` path.
#
# Unlike the pilot port (tally), none of this port's pieces are display-free
# yet: the combo-row models (Frequency, Weekday, PrunePreset) wrap
# `Gtk::StringList` and the rest of lib/pika_backup is widgets, so there is no
# half of the app that loads without `gtk4`. This simply requires the whole
# thing — spec/spec_helper.rb needs a display (xvfb-run) for that reason, same
# as test/drive_widgets.rb.
require_relative "../../pika_backup"
