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
    public class Widgets.InfoBar : Gtk.Revealer {
        private uint hiding_timer = 0;
        private uint remove_timer = 0;

        private Gtk.Label info_label;

        private Gtk.Box box_wrap;

        ~InfoBar () {
            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
            }
        }

        public InfoBar () {
            Object (valign: Gtk.Align.CENTER,
                    halign: Gtk.Align.START,
                    margin: 30);

        }

        construct {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;

            box_wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            info_label = new Gtk.Label (null);
            info_label.margin = 10;

            box_wrap.add (info_label);

            add (box_wrap);
        }

        public void reveal_control () {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
                hiding_timer = 0;
            }

            if (remove_timer != 0) {
                GLib.Source.remove (remove_timer);
                remove_timer = 0;
            }


            hiding_timer = GLib.Timeout.add (5000, () => {
                set_reveal_child (false);

                remove_timer = GLib.Timeout.add (get_transition_duration (), () => {
                    hide ();

                    remove_timer = 0;

                    return false;
                });

                hiding_timer = 0;

                return false;
            });
        }

        public void set_label (string info) {
            info_label.set_markup (info);

            show_all ();
            reveal_control ();
        }
    }
}
