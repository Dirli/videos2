namespace Videos2 {
    public class Widgets.InfoBar : Gtk.Revealer {
        private uint hiding_timer = 0;
        private uint remove_timer = 0;

        private Gtk.Box box_wrap;

        ~InfoBar () {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
            }
        }

        public InfoBar (bool has_vaapi) {
            Object (valign: Gtk.Align.START,
                    halign: Gtk.Align.START,
                    margin: 30);

            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;

            box_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            if (has_vaapi) {
                box_wrap.get_style_context ().add_class ("dark-color");
            }

            add (box_wrap);
        }

        public void reveal_control (Gtk.Label new_label) {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
                var info_lbl = box_wrap.get_children ();
                if (info_lbl.length () > 0) {
                    box_wrap.remove (info_lbl.nth_data (0));
                }
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
                remove_timer = 0;
            }

            box_wrap.add (new_label);
            show_all ();

            hiding_timer = GLib.Timeout.add (5000, () => {
                set_reveal_child (false);

                remove_timer = GLib.Timeout.add (get_transition_duration (), () => {
                    var info_lbl = box_wrap.get_children ();
                    if (info_lbl.length () > 0) {
                        box_wrap.remove (info_lbl.nth_data (0));
                    }

                    remove_timer = 0;

                    return false;
                });

                hiding_timer = 0;

                return false;
            });
        }

        public void show_volume (double vol) {
            var volume_info = new Gtk.Label (null);
            volume_info.label = "Volume: %.0f %%".printf (vol * 100);
            volume_info.get_style_context ().add_class ("info-volume");
            volume_info.margin = 6;

            reveal_control (volume_info);
        }

        public void show_media_info (string info) {
            var video_info = new Gtk.Label (null);
            video_info.get_style_context ().remove_class ("info-volume");
            video_info.margin = 12;
            video_info.set_markup (info);

            reveal_control (video_info);
        }
    }
}
