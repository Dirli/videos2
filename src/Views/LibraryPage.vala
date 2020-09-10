namespace Videos2 {
    public class Views.LibraryPage : Gtk.Paned {
        public signal void select_category (string uri);
        public signal void select_media (string uri);
        public signal void play_media (string[] medias);

        private bool exist_poster = true;
        private string poster_path = "";

        private Gtk.ListBox movies_list;
        private Widgets.MovieGrid movie_grid;
        private Gtk.ListBox categories_list;
        private Gtk.Box categories_box;

        private Tumbler? thumbnail;

        public LibraryPage () {
            Object (orientation: Gtk.Orientation.HORIZONTAL,
                    margin: 6);
        }

        construct {
            try {
                thumbnail = GLib.Bus.get_proxy_sync (GLib.BusType.SESSION,
                                                     Constants.THUMBNAILER_IFACE,
                                                     Constants.THUMBNAILER_SERVICE);

                thumbnail.finished.connect ((handle) => {
                    if (!exist_poster && poster_path != "") {
                        set_poster ();
                    }
                });
                thumbnail.ready.connect ((handle, uris) => {
                    // foreach (var uri in uris) {
                    //
                    // }
                });

            } catch (Error e) {
                warning (e.message);
                thumbnail = null;
            }

            var movies_pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);

            movie_grid = new Widgets.MovieGrid ();

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.margin_start = 6;

            movies_list = new Gtk.ListBox ();
            movies_list.selection_mode = Gtk.SelectionMode.BROWSE;
            movies_list.activate_on_single_click = false;
            movies_list.row_selected.connect (on_row_selected);
            movies_list.row_activated.connect ((item) => {
                select_media (item.name);
            });
            movies_list.set_sort_func (list_sort_func);

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

            movies_pane.pack1 (movie_grid, false, false);
            movies_pane.pack2 (scrolled_window, true, false);

            pack1 (services_box, false, false);
            pack2 (movies_pane, true, false);

            GLib.Idle.add (() => {
                on_row_selected (null);

                return false;
            });
        }

        private void on_row_selected (Gtk.ListBoxRow? item) {
            movie_grid.set_poster (null);
            exist_poster = true;
            poster_path = "";

            if (item == null) {
                movie_grid.hide ();
                return;
            }

            var selected_file = GLib.File.new_for_uri (item.name);

            try {
                var file_info = selected_file.query_info (
                    "standard::*," + GLib.FileAttribute.STANDARD_CONTENT_TYPE + "," + GLib.FileAttribute.STANDARD_SIZE,
                    GLib.FileQueryInfoFlags.NONE
                );

                movie_grid.movie_label = file_info.get_name ();
                movie_grid.movie_size = Utils.format_bytes (file_info.get_size ());

                var uri = selected_file.get_uri ();
                var discoverer_info = Utils.get_discoverer_info (uri);
                if (discoverer_info != null) {
                    var media_info = "";

                    media_info += Utils.prepare_video_info (discoverer_info);
                    media_info += Utils.prepare_audio_info (discoverer_info);
                    media_info += Utils.prepare_sub_info (discoverer_info);

                    uint64 duration = discoverer_info.get_duration ();
                    if (duration == 0) {
                        var tags = discoverer_info.get_tags ();
                        if (tags != null && !tags.get_uint64 (Gst.Tags.DURATION, out duration)) {
                            duration = 0;
                        }
                    }

                    var m_length = Utils.nano_to_sec ((int64) duration);

                    movie_grid.movie_length = Granite.DateTime.seconds_to_time ((int) m_length);
                    movie_grid.movie_info = media_info;
                }

                var poster_hash = GLib.Checksum.compute_for_string (ChecksumType.MD5, uri, uri.length);
                poster_path = Path.build_filename (GLib.Environment.get_user_cache_dir (),
                                                   "thumbnails",
                                                   "large",
                                                   poster_hash + ".png");

                if (!set_poster ()) {
                    Gee.ArrayList<string> uris = new Gee.ArrayList<string> ();
                    Gee.ArrayList<string> mimes = new Gee.ArrayList<string> ();

                    uris.add (selected_file.get_uri ());
                    mimes.add (file_info.get_content_type ());

                    instand (uris, mimes, "large");
                    exist_poster = false;
                }

                movie_grid.show_all ();
            } catch (Error e) {
                warning (e.message);
            }
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

        private int list_sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            return strcmp (row1.name, row2.name);
        }

        private bool set_poster () {
            if (!GLib.FileUtils.test (poster_path, GLib.FileTest.EXISTS)) {
                return false;
            }

            exist_poster = true;

            var poster = Utils.get_poster_from_file (poster_path);

            if (poster != null) {
                movie_grid.set_poster (poster);
            }

            return true;
        }

        public void instand (Gee.ArrayList<string> uris, Gee.ArrayList<string> mimes, string size) {
            if (thumbnail == null) {
                return;
            }

            thumbnail.queue.begin (uris.to_array (), mimes.to_array (), size, "default", 0);
        }
    }
}
