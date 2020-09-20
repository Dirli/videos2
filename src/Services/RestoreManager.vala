namespace Videos2 {
    public class Services.RestoreManager : GLib.Object {
        public int64 restore_position = 0;

        private Gee.HashMap<uint, Structs.RestoreStruct?> cache;

        public RestoreManager () {
            cache = new Gee.HashMap<uint, Structs.RestoreStruct?> ();

            load_cache ();
        }

        private void load_cache () {
            GLib.File file = Utils.get_cache_directory ().get_child ("p_cache");

            var now_time = new GLib.DateTime.now_local();
            var now_sec = now_time.to_unix();

            try {
                if (file.query_exists ()) {
                    GLib.DataInputStream dis = new GLib.DataInputStream (file.read ());
                    string line;

                    while ((line = dis.read_line ()) != null) {
                        var entry_arr = line.split ("=");
                        if (entry_arr.length < 3) {
                            continue;
                        }

                        var uri_hash = uint.parse (entry_arr[0]);
                        if (uri_hash == 0 || cache.has_key (uri_hash)) {
                            continue;
                        }


                        var uri_position = int64.parse (entry_arr[1]);
                        if (uri_position <= 0) {
                            continue;
                        }

                        int64 rec_time = int64.parse (entry_arr[2]);
                        if (rec_time == 0 || (now_sec - rec_time) / 86400 > 90) {
                            continue;
                        }

                        Structs.RestoreStruct cache_struct = {};
                        cache_struct.rec_time = rec_time;
                        cache_struct.position = uri_position;

                        cache.@set (uri_hash, cache_struct);
                    }
                }
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        private void save_cache () {
            if (cache.size == 0) {
                return;
            }

            GLib.File cache_file = Utils.get_cache_directory ().get_child ("p_cache");

            try {
                if (cache_file.query_exists ()) {
                    cache_file.delete ();
                }

                var dos = new GLib.DataOutputStream (cache_file.create (GLib.FileCreateFlags.REPLACE_DESTINATION));

                cache.foreach ((entry) => {
                    try {
                        dos.put_string (@"$(entry.key)=$(entry.value.position)=$(entry.value.rec_time)\n");
                    } catch (Error e) {
                        warning (e.message);
                    }

                    return true;
                });

            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
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

        private Structs.RestoreStruct get_cache_struct (int64 position) {
            var now = new GLib.DateTime.now_local();
            var now_sec = now.to_unix();

            Structs.RestoreStruct cache_struct = {};
            cache_struct.rec_time = now_sec;
            cache_struct.position = position;

            return cache_struct;
        }

        public void push_async (string uri, int64 position) {
            if (uri == "" || position == 0) {
                return;
            }

            cache[uri.hash ()] = get_cache_struct (position);

            new GLib.Thread<void*> ("push_async", () => {
                save_cache ();
                return null;
            });
        }

        public void push (string uri, int64 position) {
            if (uri == "" || position == 0) {
                return;
            }

            cache[uri.hash ()] = get_cache_struct (position);

            save_cache ();
        }

        public bool pull (string uri) {
            restore_position = 0;

            var uri_hash = uri.hash ();
            if (!cache.has_key (uri_hash)) {
                return false;
            }

            var pos = cache.@get (uri_hash).position;
            if (pos == 0) {
                return false;
            }

            restore_position = pos;
            cache.unset (uri_hash);

            new GLib.Thread<void*> ("pull_cache", () => {
                save_cache ();
                return null;
            });

            return true;
        }

        public void reset () {
            restore_position = 0;
        }
    }
}
