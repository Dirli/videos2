namespace Videos2 {
    public class Views.LibraryPage : Gtk.Paned {
        public signal void select_category (string uri);
        public signal void select_media (string uri);
        public signal void play_media (string[] medias);

        private Gtk.ListBox movies_list;
        private Gtk.ListBox categories_list;
        private Gtk.Box categories_box;

        private Gtk.ScrolledWindow scrolled_window;

        public LibraryPage () {
            Object (orientation: Gtk.Orientation.HORIZONTAL,
                    margin: 6);
        }

        construct {
            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.margin_start = 6;

            movies_list = new Gtk.ListBox ();
            movies_list.selection_mode = Gtk.SelectionMode.BROWSE;
            movies_list.activate_on_single_click = false;
            movies_list.row_activated.connect ((item) => {
                select_media (item.name);
            });
            movies_list.row_selected.connect ((item) => {
                if (item != null) {
                    //
                }
            });

            scrolled_window.add (movies_list);

            // categories
            var categories_header = new Gtk.Label (_("Categories"));
            categories_header.halign = Gtk.Align.START;
            categories_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            categories_list = new Gtk.ListBox ();
            categories_list.selection_mode = Gtk.SelectionMode.BROWSE;
            categories_list.can_focus = true;
            categories_list.row_activated.connect ((item) => {
                select_category (item.name);
            });

            categories_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            categories_box.margin_end = categories_box.margin_start = 12;
            categories_box.add (categories_header);
            categories_box.add (categories_list);

            var services_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            services_box.hexpand = false;
            services_box.add (categories_box);

            pack1 (services_box, false, false);
            pack2 (scrolled_window, true, false);
        }

        public void add_item (Enums.ItemType i_type, string title, string uri) {
            var item_row = new Gtk.ListBoxRow ();
            item_row.name = uri;

            var item_label = new Gtk.Label (title);
            item_label.margin = 3;
            item_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            item_row.add (item_label);
            item_row.show_all ();

            if (i_type == Enums.ItemType.CATEGORY) {
                categories_list.add (item_row);

                if (categories_list.get_children ().length () == 1) {
                    categories_box.show ();
                }
            } else if (i_type == Enums.ItemType.MEDIA) {
                item_row.margin = 3;
                item_label.halign = Gtk.Align.START;
                movies_list.add (item_row);
            }
        }

        public void clear_box () {
            foreach (Gtk.Widget item in categories_list.get_children ()) {
                categories_list.remove (item);
            }

            foreach (Gtk.Widget item in movies_list.get_children ()) {
                movies_list.remove (item);
            }

            categories_box.hide ();
        }
    }
}
