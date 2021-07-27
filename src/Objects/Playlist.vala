/*
 * Copyright (c) 2021 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Videos2 {
    public class Objects.Playlist : GLib.Object {
        public signal void play_media (string uri, int index);
        public signal void added_item (string uri, string basename);
        public signal void changed_nav (bool first, bool last);
        public signal void cleared_playlist ();

        private Gee.ArrayList<string> uris_array;

        public bool repeat_mode {
            get; set;
        }

        private int _current = -1;
        public int current {
            get {
                return _current;
            }
            set {
                _current = value;
                if (uris_array.size > value && value > -1) {
                    play_media (uris_array.@get (value), value);
                    changed_nav (value == 0, value + 1 == uris_array.size);
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

                if (repeat_mode) {
                    current = 0;
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

        public void add_media (GLib.File path, bool start_playback) {
            if (!path.query_exists ()) {
                return;
            }

            var uri = path.get_uri ();

            if (uris_array.contains (uri)) {
                return;
            }

            added_item (uri, path.get_basename ());
            uris_array.add (uri);

            if (current > -1 && uris_array.size > 1 && current + 2 == uris_array.size) {
                changed_nav (current == 0, false);
            }

            if (start_playback && uris_array.size == 1) {
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

        public string get_uri () {
            return current > -1 ? uris_array[current] : "";
        }

        public string[] get_medias () {
            uint i = 0;
            var medias = new string[uris_array.size];

            uris_array.foreach ((uri) => {
                medias[i++] = uri;
                return true;
            });

            return medias;
        }

        public bool restore_medias (string[] uris, string current_uri) {
            bool current_valid = false;
            for (int i = 0; i < uris.length; i++) {
                if (uris[i] == current_uri) {
                    _current = i;
                    current_valid = true;
                }

                add_media (GLib.File.new_for_uri (uris[i]), false);
            }

            return current_valid;
        }

        public bool clear_media (int index) {
            if (index < 0) {
                uris_array.clear ();
                current = -1;
                cleared_playlist ();
            } else {
                if (uris_array.size <= index || current == index) {
                    return false;
                }

                uris_array.remove_at (index);
            }

            return true;
        }
    }
}
