# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # DialogPage is the base class for every page that reads as a dialog inside a
  # navigation view: a title-less header bar, then a centred, clamped, scrolling
  # column of a big title, an optional subtitle, and the page's own content.
  #
  # Ported from pika-backup/src/widget/navigation/dialog_page.rs and
  # dialog_page.ui. Subclasses append their widgets with `add`, which is
  # upstream's GtkBuildable `add_child` override — in a .ui file a child of
  # PkDialogPage lands in the content box rather than replacing the page's
  # child, and `add` is how that reads without GtkBuilder.
  #
  # Upstream also declares a `show-continue-button` property. Nothing in
  # upstream reads or binds it, so it is not ported.
  class DialogPage < Adwaita::NavigationPage
    def initialize(title = "")
      super(toolbar_view, title)
      add_css_class("dialog-page")
      @can_close = true
    end

    def build
      tap do
        toolbar_view.tap do |view|
          view.add_top_bar(header_bar)
          view.content = scrolled_window
        end

        scrolled_window.child = clamp
        clamp.child = container

        container.tap do |box|
          box.append(title_label)
          box.append(subtitle_label)
          box.append(content_box)
        end

        title_label.label = title.to_s
        apply_can_close
      end
    end

    # Upstream's GtkBuildable override: a child of the page is a child of the
    # content box.
    def add(widget)
      tap { content_box.append(widget) }
    end

    # Upstream binds the big title label to the page's own `title` property, so
    # a later title change reaches the label too.
    def title=(title)
      super
      title_label.label = title.to_s
    end

    attr_reader :subtitle

    # The subtitle label is hidden rather than left blank when there is no
    # subtitle, so the column does not keep its spacing for an empty line.
    def subtitle=(subtitle)
      @subtitle = subtitle
      subtitle_label.label = subtitle.to_s
      subtitle_label.visible = !subtitle.to_s.empty?
    end

    attr_reader :can_close

    # Upstream binds `can-close` to the header bar's title buttons, so a page
    # that must not be abandoned shows no close or back button.
    def can_close=(can_close)
      @can_close = can_close
      apply_can_close
    end

    # Upstream keeps this as a weak reference to the widget a dialog should
    # activate on Enter; subclasses set and read it.
    attr_accessor :default_widget

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

    def header_bar
      @header_bar ||= Adwaita::HeaderBar.new.tap do |bar|
        bar.show_title = false
      end
    end

    def scrolled_window
      @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |window|
        window.hscrollbar_policy = :never
        window.propagate_natural_height = true
      end
    end

    def clamp = @clamp ||= Adwaita::Clamp.new

    def container
      @container ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.add_css_class("container")
        box.valign = :center
      end
    end

    def title_label
      @title_label ||= Gtk::Label.new.tap do |label|
        label.accessible_role = :caption
        label.wrap = true
        label.justify = :center
        label.add_css_class("title-2")
        label.add_css_class("header")
      end
    end

    def subtitle_label
      @subtitle_label ||= Gtk::Label.new.tap do |label|
        label.visible = false
        label.wrap = true
        label.wrap_mode = :word_char
        label.justify = :center
        label.halign = :center
        label.xalign = 0
        label.add_css_class("dim-label")
        label.add_css_class("description")
      end
    end

    def content_box
      @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.add_css_class("content")
      end
    end

    private

      def apply_can_close
        header_bar.show_start_title_buttons = @can_close
        header_bar.show_end_title_buttons = @can_close
      end
  end
end
