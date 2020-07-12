namespace Videos2 {
    public class Widgets.InfoBar : Gtk.Revealer {
        private uint hiding_timer = 0;

        private Gtk.Label info_label;

        public InfoBar () {
            Object (valign: Gtk.Align.START,
                    halign: Gtk.Align.START,
                    margin: 30);

            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        }


        construct {
            info_label = new Gtk.Label (null);

            add (info_label);
        }

        public void reveal_control () {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            hiding_timer = GLib.Timeout.add (5000, () => {
                set_reveal_child (false);
                hiding_timer = 0;

                return false;
            });
        }

        public void show_volume (double vol) {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            }

            info_label.label = "Volume: %.0f %%".printf (vol * 100);
            info_label.get_style_context ().add_class ("info-volume");

            reveal_control ();
        }

        public void show_media_info (string media_info) {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            }

            info_label.get_style_context ().remove_class ("info-volume");
            info_label.set_markup (media_info);

            reveal_control ();
        }
    }
}
