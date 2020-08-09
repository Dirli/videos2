namespace Videos2.Utils {
    public bool check_media (GLib.File media, out string filename, out string type) {
        type = "";
        filename = "";

        try {
            GLib.FileInfo info = media.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE + "," + GLib.FileAttribute.STANDARD_NAME, 0);
            unowned string content_type = info.get_content_type ();
            type = content_type;
            filename = info.get_name ();

            if (!GLib.ContentType.is_a (content_type, "video/*")) {
                return false;
            }

            return true;
        } catch (GLib.Error e) {
            debug (e.message);
        }


        return false;
    }

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

    public GLib.File[] run_file_chooser (Gtk.Window? parent) {
        var all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (_("All files"));
        all_files_filter.add_pattern ("*");

        var video_filter = new Gtk.FileFilter ();
        video_filter.set_filter_name (_("Video files"));
        video_filter.add_mime_type ("video/*");

        var file_chooser = new Gtk.FileChooserNative (_("Open"),
                                                      parent,
                                                      Gtk.FileChooserAction.OPEN,
                                                      _("Open"),
                                                      _("Cancel"));

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

    public GLib.File get_cache_directory (string child_dir = "") {
        string dir_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
                                                GLib.Environment.get_user_cache_dir (),
                                                Constants.APP_NAME,
                                                child_dir);

        var cache_dir = GLib.File.new_for_path (dir_path);

        if (!GLib.FileUtils.test (dir_path, GLib.FileTest.IS_DIR)) {
            try {
                cache_dir.make_directory_with_parents (null);
            } catch (Error e) {
                warning (e.message);
            }
        }

        return cache_dir;
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

    public string parse_bitrate (uint b) {
        return "    <b>Bitrate:</b> %.0f kbps\n".printf (b / 1000.0);
    }

    public void get_video_size (string uri, out uint width, out uint height) {
        width = 0;
        height = 0;
        var info = get_discoverer_info (uri);
        var video_streams = info.get_video_streams ();
        var stream = video_streams.nth_data (0);
        var video_stream = stream as Gst.PbUtils.DiscovererVideoInfo;
        if (video_stream != null) {
            width = video_stream.get_width ();
            height = video_stream.get_height ();
            if (width > 960 || height > 540) {
                width = (uint) (540.0 / height * width);
                height = 540;
            }
        }
    }

    public string prepare_video_info (Gst.PbUtils.DiscovererInfo d_info) {
        var video_str = "<span size=\"large\"><b>Video</b></span>\n";

        var v_streams = d_info.get_video_streams ();
        v_streams.reverse ();
        foreach (var video_info in v_streams) {
            var video_tags = video_info.get_tags ();
            if (video_tags != null) {
                string codec;
                if (video_tags.get_string (Gst.Tags.VIDEO_CODEC, out codec)) {
                    video_str += "    <b>Video codec:</b> %s\n".printf (codec);
                } else if (video_tags.get_string (Gst.Tags.CODEC, out codec)) {
                    video_str += "    <b>Video codec:</b> %s\n".printf (codec);
                }

                uint bitrate;
                if (video_tags.get_uint (Gst.Tags.BITRATE, out bitrate)) {
                    video_str += parse_bitrate (bitrate);
                } else if (video_tags.get_uint (Gst.Tags.NOMINAL_BITRATE, out bitrate)) {
                    video_str += parse_bitrate (bitrate);
                } else if (video_tags.get_uint (Gst.Tags.MAXIMUM_BITRATE, out bitrate)) {
                    video_str += parse_bitrate (bitrate);
                } else if (video_tags.get_uint (Gst.Tags.MINIMUM_BITRATE, out bitrate)) {
                    video_str += parse_bitrate (bitrate);
                }
            }

            var video_stream = video_info as Gst.PbUtils.DiscovererVideoInfo;
            if (video_stream != null) {
                video_str += "    <b>Size:</b> %u x %u \n".printf (video_stream.get_width (), video_stream.get_height ());
                video_str += "    <b>Frame rate:</b> %0.3f fps\n".printf ((double) video_stream.get_framerate_num () / video_stream.get_framerate_denom ());
            }
        }

        return video_str;
    }

    public string prepare_audio_info (Gst.PbUtils.DiscovererInfo d_info) {
        var audio_str = "<span size=\"large\"><b>Audio</b></span>\n";

        var a_streams = d_info.get_audio_streams ();
        a_streams.reverse ();
        foreach (var audio_info in a_streams) {
            var audio_stream = audio_info as Gst.PbUtils.DiscovererAudioInfo;
            uint channels = 0;
            if (audio_stream != null) {
                unowned string language_code = audio_stream.get_language ();
                if (language_code != null) {
                    audio_str += "  <b>Language:</b> %s\n".printf (Gst.Tag.get_language_name (language_code));
                }

                channels = audio_stream.get_channels ();
            }

            var audio_tags = audio_info.get_tags ();
            if (audio_tags != null) {

                string codec;
                if (audio_tags.get_string (Gst.Tags.AUDIO_CODEC, out codec)) {
                    audio_str += "    <b>Audio codec:</b> %s\n".printf (codec);
                } else if (audio_tags.get_string (Gst.Tags.CODEC, out codec)) {
                    audio_str += "    <b>Audio codec:</b> %s\n".printf (codec);
                }

                uint bitrate;
                if (audio_tags.get_uint (Gst.Tags.BITRATE, out bitrate)) {
                    audio_str += parse_bitrate (bitrate);
                } else if (audio_tags.get_uint (Gst.Tags.NOMINAL_BITRATE, out bitrate)) {
                    audio_str += parse_bitrate (bitrate);
                } else if (audio_tags.get_uint (Gst.Tags.MAXIMUM_BITRATE, out bitrate)) {
                    audio_str += parse_bitrate (bitrate);
                } else if (audio_tags.get_uint (Gst.Tags.MINIMUM_BITRATE, out bitrate)) {
                    audio_str += parse_bitrate (bitrate);
                }
            }

            audio_str += "    <b>Sample rate:</b> %0.1f kHz%s\n".printf (audio_stream.get_sample_rate () / 1000.0,
                                                                   channels > 0 ? ", <b>Channels:</b> %u".printf (channels) : "");
        }

        return audio_str;
    }

    public string prepare_sub_info (Gst.PbUtils.DiscovererInfo d_info) {
        var s_streams = d_info.get_subtitle_streams ();

        if (s_streams.length () == 0) {
            return "";
        }

        s_streams.reverse ();

        var sub_str = "<span size=\"large\"><b>Subtitles</b></span>\n";
        foreach (var sub_info in s_streams) {
            var sub_stream = sub_info as Gst.PbUtils.DiscovererSubtitleInfo;
            if (sub_stream != null) {
                unowned string language_code = sub_stream.get_language ();
                if (language_code != null) {
                    sub_str += Gst.Tag.get_language_name (language_code) + ", ";
                }
            }
        }

        return sub_str;
    }
}
