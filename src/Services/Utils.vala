namespace Videos2.Utils {
    public string get_title (string filename) {
        var title = get_basename (filename);
        title = GLib.Uri.unescape_string (title);
        title = title.replace ("_", " ").replace (".", " ").replace ("  ", " ");

        return title;
    }

    public string get_basename (string filename) {
        var basename = GLib.Path.get_basename (filename);

        var index_of_last_dot = basename.last_index_of (".");
        var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);

        return launcher_base;
    }

    public GLib.File[] run_file_chooser () {
        var all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (_("All files"));
        all_files_filter.add_pattern ("*");

        var video_filter = new Gtk.FileFilter ();
        video_filter.set_filter_name (_("Video files"));
        video_filter.add_mime_type ("video/*");

        var file_chooser = new Gtk.FileChooserNative (_("Open"),
                                                      null,
                                                      Gtk.FileChooserAction.OPEN,
                                                      _("_Open"),
                                                      _("_Cancel"));

        file_chooser.select_multiple = true;
        file_chooser.add_filter (video_filter);
        file_chooser.add_filter (all_files_filter);

        GLib.File[] files = {};
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            foreach (GLib.File item in file_chooser.get_files ()) {
                files += item;
            }
        }

        file_chooser.destroy ();

        return files;
    }

    public inline int64 sec_to_nano (int64 seconds) {
        return (int64) (seconds * Constants.NANO_INV / Constants.SEC_INV);
    }

    public static Gst.PbUtils.DiscovererInfo? get_discoverer_info (string uri) {
        Gst.PbUtils.Discoverer discoverer = null;
        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (Constants.DISCOVERER_TIMEOUT * Gst.SECOND));
        } catch (Error e) {
            debug ("Could not create Gst discoverer object: %s", e.message);
        }

        Gst.PbUtils.DiscovererInfo discoverer_info = null;
        try {
            discoverer_info = discoverer.discover_uri (uri);
        } catch (Error e) {
            debug ("Discoverer Error %d: %s\n", e.code, e.message);
        }

        return discoverer_info;
    }
}
