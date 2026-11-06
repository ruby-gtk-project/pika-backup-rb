# frozen_string_literal: true

require_relative "pika_backup/application"

# Models behind the schedule page's combo rows.
require_relative "pika_backup/frequency"
require_relative "pika_backup/weekday"
require_relative "pika_backup/prune_preset"

# Reusable widgets the pages are built from.
require_relative "pika_backup/status_icon"
require_relative "pika_backup/status_row"
require_relative "pika_backup/location_tag"
require_relative "pika_backup/folder_row"

# Base classes for pages inside a navigation view.
require_relative "pika_backup/dialog_page"
require_relative "pika_backup/spinner_page"

# The main window and the overview page it opens on.
require_relative "pika_backup/overview_row"
require_relative "pika_backup/overview_page"
require_relative "pika_backup/app_window"
