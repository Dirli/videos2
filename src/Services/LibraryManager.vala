namespace Videos2 {
    public class Services.LibraryManager : GLib.Object {
        public signal void item_found (Enums.ItemType i_type, string title, string uri);
        public signal void parents_found (GLib.Array<GLib.File> paths);

        public string current_uri {
            get;
            private set;
        }

        private string root_uri;
        public string root_path {
            set {
                var f = GLib.File.new_for_path (value);
                root_uri = f.get_uri ();
            }
        }

        private int _categories_count;
        public int categories_count {
            get {
                return _categories_count;
            }
            set {
                _categories_count = value;
                current_uri = "";
            }
        }

        public int cat_count = 0;

        public LibraryManager (int c_count) {
            _categories_count = c_count;
            current_uri = "";
        }

        public void init (string uri) {
            if (root_uri == "") {
                return;
            }

            var parent_paths = new GLib.Array<GLib.File> ();

            cat_count = 0;
            if (uri == "") {
                if (current_uri != "") {
                    if (!check_nesting (current_uri, ref parent_paths)) {
                        return;
                    }

                    scan_directory (current_uri, cat_count < categories_count);
                } else {
                    scan_directory (root_uri, cat_count < categories_count);
                }
            } else if (uri == root_uri) {
                current_uri = "";

                scan_directory (root_uri, cat_count < categories_count);
            } else {
                if (!check_nesting (uri, ref parent_paths)) {
                    return;
                }

                current_uri = uri;

                scan_directory (current_uri, cat_count < categories_count);
            }

            parents_found (parent_paths);
        }

        private bool check_nesting (string uri, ref GLib.Array<GLib.File> paths) {
            GLib.File f = GLib.File.new_for_uri (uri);

            int find_count = 0;
            while ((f = f.get_parent ()) != null) {
                if (++find_count > categories_count) {
                    return false;
                }

                paths.prepend_val (f);

                if (f.get_uri () == root_uri) {
                    cat_count = find_count;
                    return true;
                }
            }

            return false;
        }

        private void scan_directory (string uri, bool search_cat = false) {
            GLib.File directory = GLib.File.new_for_uri (uri.replace ("#", "%23"));

            try {
                var children = directory.enumerate_children (
                    "standard::*," + FileAttribute.STANDARD_CONTENT_TYPE + "," + FileAttribute.STANDARD_IS_HIDDEN + "," + FileAttribute.STANDARD_IS_SYMLINK + "," + FileAttribute.STANDARD_SYMLINK_TARGET,
                    GLib.FileQueryInfoFlags.NONE
                );
                GLib.FileInfo file_info = null;

                while ((file_info = children.next_file ()) != null) {
                    if (file_info.get_is_hidden ()) {
                        continue;
                    }

                    if (file_info.get_is_symlink ()) {
                        string target = file_info.get_symlink_target ();
                        var symlink = GLib.File.new_for_path (target);
                        var file_type = symlink.query_file_type (0);

                        if (file_type == GLib.FileType.DIRECTORY) {
                            scan_directory (target, search_cat);
                        }
                    } else if (file_info.get_file_type () == GLib.FileType.DIRECTORY) {
                        if (search_cat) {
                            var f_name = file_info.get_name ();
                            item_found (Enums.ItemType.CATEGORY, f_name,  directory.get_uri () + "/" + f_name);
                        } else {
                            scan_directory (directory.get_uri () + "/" + file_info.get_name ());
                        }
                    } else {
                        string mime_type = file_info.get_content_type ();
                        if (!file_info.get_is_hidden () && mime_type.contains ("video")) {
                            var f_name = file_info.get_name ();
                            var f_uri = directory.get_uri () + "/" + file_info.get_name ().replace ("#", "%23").replace ("%", "%25");
                            item_found (Enums.ItemType.MEDIA,
                                        f_name,
                                        f_uri);
                        }
                    }
                }

                children.close ();
                children.dispose ();
            } catch (Error err) {
                warning ("%s\n%s", err.message, uri);
            }

            directory.dispose ();
        }
    }
}
