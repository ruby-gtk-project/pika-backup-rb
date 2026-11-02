# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # StatusIcon is the round status badge shown in front of a status row: an
  # icon tinted by severity, or a spinner while an operation runs.
  #
  # Ported from pika-backup/src/widget/status_icon.rs. Upstream is a
  # GtkBox subclass holding a GtkStack that swaps between a GtkImage and an
  # AdwSpinner, with `icon-name` and `level` as GObject properties bound to the
  # image. The Ruby bindings cannot add GObject properties to a Ruby subclass,
  # so the two properties are plain Ruby accessors that write through to the
  # image instead of being bound to it — the observable behaviour is the same.
  #
  # The severity levels are upstream's `crate::utils::StatusLevel`, and
  # `Graphic` is upstream's `backup_status::Graphic`. Both are declared here
  # because this widget is their only consumer; they move to ui_utils.rb and
  # backup_status.rb when those components are ported.
  class StatusIcon < Gtk::Box
    LEVELS = %i[ok neutral warning error spinner].freeze

    # The CSS classes style.css defines for the tinted states. :neutral has no
    # class (the plain icon colour) and :spinner shows the spinner instead.
    LEVEL_CSS_CLASSES = {
      ok:      "ok-icon",
      warning: "warning-icon",
      error:   "error-icon",
    }.freeze

    # What a status wants drawn: an icon at some severity, or a spinner.
    Graphic = Data.define(:level, :icon_name) do
      def self.ok_icon(icon_name) = new(level: :ok, icon_name: icon_name)
      def self.warning_icon(icon_name) = new(level: :warning, icon_name: icon_name)
      def self.error_icon(icon_name) = new(level: :error, icon_name: icon_name)
      def self.spinner = new(level: :spinner, icon_name: nil)

      def spinner? = level == :spinner
    end

    def initialize(icon_name = "", level = :neutral)
      super(:horizontal, 0)
      @level = level
      self.icon_name = icon_name
    end

    def build
      tap do
        stack.tap do |st|
          st.add_child(image)
          st.add_child(spinner)
          st.visible_child = image
        end

        append(stack)
        apply_level(@level)
      end
    end

    def icon_name = image.icon_name

    def icon_name=(icon_name)
      image.icon_name = icon_name.to_s
    end

    attr_reader :level

    # Upstream short-circuits an unchanged level so the CSS classes are not
    # churned on every status refresh.
    def level=(level)
      unless level == @level
        apply_level(level)
      end
    end

    def set_from_graphic(graphic)
      unless graphic.icon_name.nil?
        self.icon_name = graphic.icon_name
      end

      self.level = graphic.level
    end

    def set_neutral = self.level = :neutral
    def set_ok = self.level = :ok
    def set_warning = self.level = :warning
    def set_error = self.level = :error
    def set_spinner = self.level = :spinner

    def image
      @image ||= Gtk::Image.new.tap do |img|
        img.add_css_class("status-icon")
        img.valign = :center
      end
    end

    def spinner
      @spinner ||= Adwaita::Spinner.new.tap do |sp|
        sp.add_css_class("row-icon")
        sp.width_request = 24
        sp.height_request = 24
        sp.valign = :center
        sp.halign = :center
      end
    end

    def stack = @stack ||= Gtk::Stack.new

    private

      def apply_level(level)
        LEVEL_CSS_CLASSES.each_value { |css_class| image.remove_css_class(css_class) }
        show(image)

        LEVEL_CSS_CLASSES[level].then do |css_class|
          if css_class
            image.add_css_class(css_class)
          end
        end

        if level == :spinner
          show(spinner)
        end

        @level = level
      end

    # A level can be set before `build` has parented the children, and GTK
    # refuses a `visible-child` that is not in the stack yet. `build` replays
    # the level once the stack is populated, so skipping here loses nothing.
      def show(child)
        if child.parent == stack
          stack.visible_child = child
        end
      end
  end
end
