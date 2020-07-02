namespace Videos2 {
    public class Objects.Playlist : GLib.Object {
        public signal void play_media (string uri, int index);
        public signal void added_item (string uri, string basename);
        public signal void cleared_playlist ();

        private Gee.ArrayList<string> uris_array;

        private int _current = -1;
        public int current {
            get {
                return _current;
            }
            set {
                _current = value;
                if (uris_array.size > value && value > -1) {
                    play_media (uris_array.@get (value), value);
                }
            }
        }

        public Playlist () {
            uris_array = new Gee.ArrayList<string> ();
        }

        public bool next () {
            if (current > -1) {
                if (current + 1 < uris_array.size) {
                    ++current;
                    return true;
                }
            }

            return false;
        }

        public bool previous () {
            if (current > -1) {
                if (current - 1 > -1) {
                    --current;
                    return true;
                }
            }

            return false;
        }

        public void add_media (GLib.File path) {
            if (!path.query_exists ()) {
                return;
            }

            var uri = path.get_uri ();

            if (uris_array.contains (uri)) {
                return;
            }

            added_item (uri, path.get_basename ());
            uris_array.add (uri);
            if (uris_array.size == 1) {
                current = 0;
            }
        }

        public int change_media_position (int old_position, int new_position) {
            if (old_position < uris_array.size) {
                var played_uri = uris_array.@get (current);
                var moved_uri = uris_array.remove_at (old_position);
                uris_array.insert (new_position, moved_uri);

                _current = uris_array.index_of (played_uri);
            }

            return current;
        }

        public void select_media (string uri) {
            var index = uris_array.index_of (uri);
            if (index > -1) {
                current = index;
            }
        }

        public string[] get_medias () {
            uint i = 0;
            var medias = new string[uris_array.size];

            uris_array.foreach ((uri) => {
                medias[i++] = uri;
                // i++;
                return true;
            });

            return medias;
        }

        public void remove_media () {}

        public void clear_media () {
            uris_array.clear ();
            current = -1;
            cleared_playlist ();
        }
    }
}
