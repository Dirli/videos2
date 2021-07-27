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
    public class Widgets.MovieGrid : Gtk.Box {
        private Gtk.Image poster;

        private Gtk.Label _movie_label;
        public string movie_label {
            set {
                _movie_label.label = value;
            }
        }
        private Gtk.Label _movie_size;
        public string movie_size {
            set {
                _movie_size.label = "Size: " + value;
            }
        }

        private Gtk.Label _movie_length;
        public string movie_length {
            set {
                _movie_length.label = "Length: " + value;
            }
        }

        private Gtk.Label _movie_info;
        public string movie_info {
            set {
                _movie_info.set_markup (value);
            }
        }

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
            _movie_label = new Gtk.Label ("");
            _movie_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            _movie_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            _movie_size = new Gtk.Label ("");
            _movie_length = new Gtk.Label ("");

            _movie_info = new Gtk.Label ("");
            _movie_info.halign = Gtk.Align.START;

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.add (_movie_info);

            poster = new Gtk.Image ();
            poster.height_request = 256;
            poster.width_request = 256;

            var style_context = poster.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_CARD);
            style_context.add_class ("default-thumbnail");

            var info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 24);
            info_box.halign = Gtk.Align.CENTER;

            info_box.add (_movie_length);
            info_box.add (_movie_size);

            var info_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            info_wrap.add (_movie_label);
            info_wrap.add (info_box);
            info_wrap.add (scrolled_window);

            add (poster);
            add (info_wrap);
        }

        public void set_poster (Gdk.Pixbuf? new_poster) {
            poster.set_from_pixbuf (new_poster);
        }
    }
}
