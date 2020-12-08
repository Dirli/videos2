namespace Videos2 {
    public class Widgets.PropsBar : Gtk.EventBox {
        private uint hiding_timer = 0;

        private Gtk.Label info_label;


        public PropsBar () {
            Object (valign: Gtk.Align.START,
                    halign: Gtk.Align.END,
                    margin_top: 40,
                    margin_end: 30);
        }

        construct {
            get_style_context ().add_class ("info-wrapper");

            info_label = new Gtk.Label (null);
            info_label.margin = 6;
            info_label.get_style_context ().add_class ("info-volume");

            add (info_label);
        }

        public new void set_label (string lbl) {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            } else {
                show ();
            }

            hiding_timer = GLib.Timeout.add (5000, () => {
                hide ();

                hiding_timer = 0;
                return false;
            });

            info_label.set_label (lbl);
        }
    }
}
