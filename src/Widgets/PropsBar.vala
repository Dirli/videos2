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
    public class Widgets.PropsBar : Gtk.EventBox {
        private uint hiding_timer = 0;

        private Gtk.Label info_label;


        public PropsBar () {
            Object (valign: Gtk.Align.START,
                    halign: Gtk.Align.END,
                    margin_top: 40,
                    margin_end: 30);
        }

        construct {
            info_label = new Gtk.Label (null);
            info_label.margin = 6;
            info_label.get_style_context ().add_class ("info-volume");

            add (info_label);
        }

        public void set_label (string lbl) {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            } else {
                show ();
            }

            hiding_timer = GLib.Timeout.add (5000, () => {
                hide ();

                hiding_timer = 0;
                return false;
            });

            info_label.set_label (lbl);
        }
    }
}
