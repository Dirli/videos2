namespace Videos2 {
    public class Widgets.HeadBar : Gtk.HeaderBar {
        public signal void navigation_clicked ();
        public signal void audio_selected (int i);
        public signal void subtitle_selected (int i);
        public signal void show_preferences ();

        private Gtk.Button nav_button;
        private Gtk.ComboBoxText audio_streams;
        private Gtk.ComboBoxText sub_streams;

        public bool navigation_visible {
            set {
                if (nav_button.visible != value) {
                    if (value) {
                        nav_button.show ();
                    } else {
                        nav_button.hide ();
                    }
                }
            }
        }

        public string navigation_label {
            get {
                return nav_button.label;
            }
            set {
                nav_button.label = value;
            }
        }

        public HeadBar () {
            Object (show_close_button: true);

        }

        construct {
            get_style_context ().add_class ("compact");

            int top = 0;

            var menu_grid = new Gtk.Grid ();
            menu_grid.column_spacing = 12;
            menu_grid.row_spacing = 6;
            menu_grid.margin = 6;

            var audio_label = new Gtk.Label (_("Audio:"));
            audio_label.halign = Gtk.Align.END;

            audio_streams = new Gtk.ComboBoxText ();
            audio_streams.append ("none", _("None"));
            audio_streams.sensitive = false;

            var sub_label = new Gtk.Label (_("Subtitles:"));
            sub_label.halign = Gtk.Align.END;

            sub_streams = new Gtk.ComboBoxText ();
            sub_streams.append ("none", _("None"));
            sub_streams.sensitive = false;

            menu_grid.attach (audio_label, 0, top, 1, 1);
            menu_grid.attach (audio_streams, 1, top++, 1, 1);
            menu_grid.attach (sub_label, 0, top, 1, 1);
            menu_grid.attach (sub_streams, 1, top++, 1, 1);

            var pref_button = new Gtk.ModelButton ();
            pref_button.text = _("Preferences");
            pref_button.clicked.connect (() => {
                show_preferences ();
            });

            var about_button = new Gtk.ModelButton ();
            about_button.text = _("About");
            about_button.clicked.connect (() => {
                var about = new Dialogs.About ();
                about.run ();
            });

            menu_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, top++, 2, 1);
            menu_grid.attach (pref_button, 0, top++, 2, 1);
            menu_grid.attach (about_button, 0, top++, 2, 1);

            menu_grid.show_all ();
            var popover_menu = new Gtk.Popover (null);
            popover_menu.add (menu_grid);

            var menu_button = new Gtk.MenuButton ();
            menu_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            menu_button.popover = popover_menu;
            menu_button.valign = Gtk.Align.CENTER;

            pack_end (menu_button);

            show_all ();

            nav_button = new Gtk.Button ();
            nav_button.label = Constants.NAV_BUTTON_WELCOME;
            nav_button.valign = Gtk.Align.CENTER;
            nav_button.vexpand = false;
            nav_button.get_style_context ().add_class ("back-button");
            nav_button.clicked.connect (() => {
                navigation_clicked ();
            });

            pack_start (nav_button);

            audio_streams.changed.connect (on_audio_changed);
            sub_streams.changed.connect (on_subtitles_changed);
        }

        private void on_audio_changed () {
            if (audio_streams.active < 0 || audio_streams.active_id == "def" || audio_streams.active_id == "none") {
                return;
            }

            audio_selected (audio_streams.active);
        }

        private void on_subtitles_changed () {
            if (sub_streams.active < 0) {
                return;
            }

            subtitle_selected (sub_streams.active_id == "none" ? -1 : sub_streams.active);
        }

        public void set_active_audio (int active_index) {
            if (active_index == audio_streams.active || active_index == -1) {
                return;
            }

            audio_streams.changed.disconnect (on_audio_changed);
            audio_streams.active = active_index;
            audio_streams.changed.connect (on_audio_changed);
        }

        public void clear_meta () {
            audio_streams.changed.disconnect (on_audio_changed);
            if (audio_streams.model.iter_n_children (null) > 0) {
                audio_streams.remove_all ();
            }

            audio_streams.sensitive = false;
            audio_streams.changed.connect (on_audio_changed);

            sub_streams.changed.disconnect (on_subtitles_changed);
            if (sub_streams.model.iter_n_children (null) > 0) {
                sub_streams.remove_all ();
            }

            sub_streams.sensitive = false;
            sub_streams.changed.connect (on_subtitles_changed);
        }

        public void setup_uri_meta (string uri) {
            var discoverer_info = Utils.get_discoverer_info (uri);
            if (discoverer_info != null) {
                audio_streams.changed.disconnect (on_audio_changed);
                if (audio_streams.model.iter_n_children (null) > 0) {
                    audio_streams.remove_all ();
                }

                setup_audio (discoverer_info);

                audio_streams.changed.connect (on_audio_changed);

                sub_streams.changed.disconnect (on_subtitles_changed);

                if (sub_streams.model.iter_n_children (null) > 0) {
                    sub_streams.remove_all ();
                }

                int none_index = setup_subtitles (discoverer_info);

                sub_streams.changed.connect (on_subtitles_changed);
                sub_streams.active = none_index;
            }
        }

        private void setup_audio (Gst.PbUtils.DiscovererInfo discoverer_info) {
            var a_streams = discoverer_info.get_audio_streams ();

            if (a_streams.length () > 1) {
                int track = 1;
                foreach (var stream_info in a_streams) {
                    var audio_stream = stream_info as Gst.PbUtils.DiscovererAudioInfo;
                    if (audio_stream != null) {
                        unowned string language_code = audio_stream.get_language ();

                        if (language_code != null) {
                            unowned string language_name = Gst.Tag.get_language_name (language_code);
                            audio_streams.prepend ("", language_name);
                        } else {
                            audio_streams.prepend ("", _("Track '%u'").printf (track));
                        }
                    }

                    track++;
                }
            } else {
                audio_streams.append ("def", _("Default"));
                audio_streams.active = 0;
            }

            audio_streams.sensitive = a_streams.length () > 1;
        }

        private int setup_subtitles (Gst.PbUtils.DiscovererInfo discoverer_info) {
            var s_streams = discoverer_info.get_subtitle_streams ();
            int track = 1;
            foreach (var stream_info in s_streams) {
                var sub_stream = stream_info as Gst.PbUtils.DiscovererSubtitleInfo;
                if (sub_stream != null) {
                    unowned string language_code = sub_stream.get_language ();
                    if (language_code != null) {
                        unowned string language_name = Gst.Tag.get_language_name (language_code);
                        sub_streams.prepend ("", language_name);
                    } else {
                        sub_streams.prepend ("", _("Track '%u'").printf (track));
                    }
                }

                track++;
            }

            sub_streams.append ("none", _("None"));
            sub_streams.sensitive = s_streams.length () > 0;

            return (int) s_streams.length ();
        }

        public void next_audio () {
            int count = audio_streams.model.iter_n_children (null);
            if (count > 0) {
                audio_streams.active = (audio_streams.active + 1) % count;
            }
        }

        public void next_subtitles () {
            int count = sub_streams.model.iter_n_children (null);
            if (count > 0) {
                sub_streams.active = (sub_streams.active + 1) % count;
            }
        }
    }
}
