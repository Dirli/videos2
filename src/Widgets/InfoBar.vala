namespace Videos2 {
    public class Widgets.InfoBar : Gtk.Revealer {
        private uint hiding_timer = 0;
        private uint remove_timer = 0;

        private Gtk.Label info_label;

        private Gtk.Box box_wrap;

        ~InfoBar () {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
            }
        }

        public InfoBar () {
            Object (valign: Gtk.Align.CENTER,
                    halign: Gtk.Align.START,
                    margin: 30);

        }

        construct {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;

            box_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            info_label = new Gtk.Label (null);
            info_label.margin = 10;

            box_wrap.add (info_label);

            add (box_wrap);
        }

        public void reveal_control () {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
                remove_timer = 0;
            }


            hiding_timer = GLib.Timeout.add (5000, () => {
                set_reveal_child (false);

                remove_timer = GLib.Timeout.add (get_transition_duration (), () => {
                    hide ();

                    remove_timer = 0;

                    return false;
                });

                hiding_timer = 0;

                return false;
            });
        }

        public void set_label (string info) {
            info_label.set_markup (info);

            show_all ();
            reveal_control ();
        }
    }
}
