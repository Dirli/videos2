namespace Videos2 {
    public class Widgets.MovieGrid : Gtk.Box {
        private Gtk.Image poster;

        private Gtk.Label movie_label;
        private Gtk.Label movie_size;
        private Gtk.Label movie_info;

        private string _movie_uri;
        public string movie_uri {
            get {
                return _movie_uri;
            }
            set {
                _movie_uri = value;
            }
        }

        public MovieGrid () {
            Object (valign: Gtk.Align.CENTER,
                    margin: 12,
                    expand: true,
                    spacing: 12,
                    orientation: Gtk.Orientation.HORIZONTAL);
        }

        construct {
            movie_label = new Gtk.Label ("");
            movie_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            movie_size = new Gtk.Label ("");
            movie_size.halign = Gtk.Align.START;

            movie_info = new Gtk.Label ("");
            movie_info.halign = Gtk.Align.START;

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            // scrolled_window.margin_start = 6;
            scrolled_window.add (movie_info);

            poster = new Gtk.Image ();
            poster.height_request = 256;
            poster.width_request = 256;

            var style_context = poster.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_CARD);
            style_context.add_class ("default-thumbnail");

            var info_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            info_wrap.add (movie_label);
            info_wrap.add (movie_size);
            info_wrap.add (scrolled_window);

            add (poster);
            add (info_wrap);
        }

        public void set_poster (Gdk.Pixbuf? new_poster) {
            poster.set_from_pixbuf (new_poster);
        }

        public void set_info (string lbl, string size) {
            movie_label.label = lbl;
            movie_size.label = "Size: " + size;
        }

        public void show_media_info (string info) {
            movie_info.set_markup (info);
        }
    }
}
