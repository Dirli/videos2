namespace Videos2 {
    public class Widgets.HeadBar : Gtk.HeaderBar {
        public signal void navigation_clicked ();
        public signal void select_category (string uri);

        private Gtk.Button nav_button;
        private Gtk.MenuButton lib_nav_button;

        private Gtk.Box lib_nav_box;

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

        public bool library_button_visible {
            set {
                if (lib_nav_button.visible != value) {
                    if (value) {
                        if (lib_nav_box.get_children ().length () == 0) {
                            return;
                        }

                        lib_nav_button.show ();
                    } else {
                        lib_nav_button.hide ();
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

            show_all ();

            nav_button = new Gtk.Button ();
            nav_button.label = Constants.NAV_BUTTON_WELCOME;
            nav_button.valign = Gtk.Align.CENTER;
            nav_button.vexpand = false;
            nav_button.get_style_context ().add_class ("back-button");
            nav_button.clicked.connect (() => {
                navigation_clicked ();
            });

            lib_nav_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            lib_nav_box.show_all ();

            var popover_lib_nav = new Gtk.Popover (null);
            popover_lib_nav.add (lib_nav_box);

            lib_nav_button = new Gtk.MenuButton ();
            lib_nav_button.image = new Gtk.Image.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            lib_nav_button.popover = popover_lib_nav;
            lib_nav_button.valign = Gtk.Align.CENTER;

            pack_start (nav_button);
            pack_start (lib_nav_button);
        }

        public void add_lib_path (GLib.Array<GLib.File> paths) {
            foreach (unowned Gtk.Widget item in lib_nav_box.get_children ()) {
                lib_nav_box.remove (item);
            }

            if (paths.length == 0) {
                library_button_visible = false;
            } else {
                for (int i = 0; i < paths.length; i++) {
                    GLib.File f = paths.index (i);

                    var lib_path_button = new Gtk.ModelButton ();

                    lib_path_button.text = f.get_basename ();
                    lib_path_button.clicked.connect (() => {
                        select_category (f.get_uri ());
                    });

                    lib_path_button.show_all ();

                    lib_nav_box.add (lib_path_button);
                }

                library_button_visible = true;
            }
        }
    }
}
