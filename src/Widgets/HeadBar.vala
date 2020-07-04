namespace Videos2 {
    public class Widgets.HeadBar : Gtk.HeaderBar {
        public signal void navigation_clicked (string navigation_label);

        private Gtk.Button nav_button;

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
            set {
                nav_button.label = value;
            }
        }

        public HeadBar () {
            Object (show_close_button: true);

        }

        construct {
            get_style_context ().add_class ("compact");

            show_all ();

            nav_button = new Gtk.Button ();
            nav_button.label = Constants.NAV_BUTTON_WELCOME;
            nav_button.valign = Gtk.Align.CENTER;
            nav_button.vexpand = false;
            nav_button.get_style_context ().add_class ("back-button");
            nav_button.clicked.connect (navigation_click);

            pack_start (nav_button);
        }

        public void navigation_click () {
            string current_label = nav_button.label;
            navigation_clicked (current_label);

            // navigation_visible = false;
        }
    }
}
