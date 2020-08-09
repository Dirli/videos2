namespace Videos2 {
    public class Services.RestoreManager : GLib.Object {
        public int64 restore_position = 0;

        private Gee.HashMap<uint, int64?> cache;

        public RestoreManager () {
            cache = new Gee.HashMap<uint, int64?> ();

            load_cache ();
        }

        private void load_cache () {
            GLib.File file = Utils.get_cache_directory ().get_child ("p_cache");

            try {
                if (file.query_exists ()) {
                    GLib.DataInputStream dis = new GLib.DataInputStream (file.read ());
                    string line;

                    while ((line = dis.read_line ()) != null) {
                        var entry_arr = line.split ("=");
                        if (entry_arr.length == 2) {
                            var uri_hash = uint.parse (entry_arr[0]);
                            if (uri_hash == 0 || cache.has_key (uri_hash)) {
                                continue;
                            }

                            var uri_position = int64.parse (entry_arr[1]);
                            if (uri_position <= 0) {
                                continue;
                            }

                            cache.@set (uri_hash, uri_position);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        private void save_cache () {
            new GLib.Thread<void*> ("save_cache", () => {
                if (cache.size == 0) {
                    return null;
                }

                GLib.File cache_file = Utils.get_cache_directory ().get_child ("p_cache");

                try {
                    if (cache_file.query_exists ()) {
                        cache_file.delete ();
                    }

                    var dos = new GLib.DataOutputStream (cache_file.create (GLib.FileCreateFlags.REPLACE_DESTINATION));

                    cache.foreach ((entry) => {
                        try {
                            dos.put_string (@"$(entry.key)=$(entry.value)\n");
                        } catch (Error e) {
                            warning (e.message);
                        }

                        return true;
                    });

                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                }

                return null;
            });
        }

        public void clear_cache () {
            cache.clear ();

            GLib.File cache_file = Utils.get_cache_directory ().get_child ("p_cache");

            try {
                if (cache_file.query_exists ()) {
                    cache_file.delete ();
                }
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        public void push (string uri, int64 position) {
            if (uri == "" || position == 0) {
                return;
            }

            cache[uri.hash ()] = position;

            GLib.Timeout.add (1000, () => {
                save_cache ();
                return false;
            });
        }

        public bool pull (string uri) {
            restore_position = 0;

            var uri_hash = uri.hash ();
            if (!cache.has_key (uri_hash)) {
                return false;
            }

            var pos = cache.@get (uri_hash);
            if (pos == 0) {
                return false;
            }

            restore_position = pos;
            cache.unset (uri_hash);

            return true;
        }

        public void reset () {
            restore_position = 0;
        }
    }
}
