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

            int top = 0;

            var menu_grid = new Gtk.Grid ();
            menu_grid.column_spacing = 12;
            menu_grid.row_spacing = 6;
            menu_grid.margin = 6;

            var about_button = new Gtk.ModelButton ();
            about_button.text = _("About");
            about_button.clicked.connect (() => {
                var about = new Dialogs.About ();
                about.run ();
            });

            menu_grid.attach (about_button, 0, top++);

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
