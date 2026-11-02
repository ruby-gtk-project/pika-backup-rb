# frozen_string_literal: true

require "adwaita"

module PikaBackup
  # LocationTag renders one included folder or one exclusion rule as a pill:
  # a symbolic icon plus an ellipsized label, with the `tag` CSS class that
  # style.css rounds off.
  #
  # Ported from pika-backup/src/widget/location_tag.rs. Upstream is an enum
  # with a Location and an Exclude variant; here the two variants are the two
  # factory methods, and the variant decides where the label and icon come
  # from.
  #
  # `from_exclude` takes the exclusion rule as a collaborator and asks it for
  # its own `description` and `symbolic_icon`, which is what upstream's
  # `config::Exclude` provides. That config type is not ported yet, so any
  # object answering those two messages works here.
  class LocationTag
    # Upstream's `config::display_path`: the backup root is stored as the empty
    # relative path, and shows as "Home" rather than as a blank label.
    HOME_LABEL = "Home"

    MISSING_FILE_ICON = "warning-symbolic"
    MISSING_FILE_TOOLTIP = "No such file or directory"

    def self.from_path(path) = new(path: path)
    def self.from_exclude(exclude) = new(exclude: exclude)

    def initialize(path: nil, exclude: nil)
      @path = path
      @exclude = exclude
    end

    def build
      box.tap do |b|
        icon.then do |image|
          if image
            b.append(image)
          end
        end

        b.append(label)
      end
    end

    def box
      @box ||= Gtk::Box.new(:horizontal, 4).tap do |b|
        b.valign = :center
        b.add_css_class("tag")
      end
    end

    def label
      @label ||= Gtk::Label.new(label_text).tap do |lbl|
        lbl.ellipsize = :middle
        lbl.natural_wrap_mode = :none
      end
    end

    def label_text
      if @exclude
        @exclude.description
      else
        display_path
      end
    end

    def icon
      if @exclude
        @exclude.symbolic_icon
      else
        file_symbolic_icon(absolute_path)
      end
    end

    private

      def display_path
        if @path.to_s.empty?
          HOME_LABEL
        else
          @path.to_s
        end
      end

    # Upstream's `config::absolute`: stored paths are relative to home unless
    # they are already absolute.
      def absolute_path
        if @path.to_s.start_with?("/")
          @path.to_s
        else
          File.join(GLib.home_dir, @path.to_s)
        end
      end

    # Upstream's `common::utils::file_symbolic_icon`: the file's own symbolic
    # icon, a warning icon when the path is gone, and no icon at all when the
    # lookup fails for any other reason.
      def file_symbolic_icon(path)
        Gio::File.new_for_path(path)
          .query_info("standard::symbolic-icon", :none)
          .symbolic_icon
          .then { |gicon| Gtk::Image.new(gicon: gicon) }
      rescue Gio::IOError::NotFound
        Gtk::Image.new(icon_name: MISSING_FILE_ICON).tap do |image|
          image.tooltip_text = MISSING_FILE_TOOLTIP
        end
      rescue Gio::IOError
        nil
      end
  end
end
