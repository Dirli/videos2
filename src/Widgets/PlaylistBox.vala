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
    public class Widgets.PlaylistBox : Gtk.ListBox {
        public signal int dnd_media (int old_position, int new_position);

        private int current = -1;

        public PlaylistBox () {
            Object (can_focus: true,
                    expand: true,
                    activate_on_single_click: false,
                    selection_mode: Gtk.SelectionMode.BROWSE);
        }

        construct {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, Constants.TARGET_ENTRIES, Gdk.DragAction.MOVE);
            drag_data_received.connect (on_drag_data_received);
        }

        public void remove_item (uint index) {
            var playlist_item = get_children ().nth_data (index);

            remove (playlist_item);
        }

        public void set_current (int index) {
            if (index == current) {
                return;
            }

            if (current > -1) {
                var past_item = get_children ().nth_data ((uint) current) as Widgets.PlaylistItem;
                if (past_item != null) {
                    past_item.is_playing = false;
                }
            }

            current = index;
            if (current > -1) {
                var next_item = get_children ().nth_data ((uint) index) as Widgets.PlaylistItem;
                if (next_item != null) {
                    next_item.is_playing = true;
                }
            }
        }

        private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
            Widgets.PlaylistItem? target = get_row_at_y (y) as Widgets.PlaylistItem;
            if (target == null) {
                return;
            }

            Gtk.Widget row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            Widgets.PlaylistItem source = (Widgets.PlaylistItem) row.get_ancestor (typeof (Widgets.PlaylistItem));

            int new_position = target.get_index ();
            int old_position = source.get_index ();

            if (source == target) {
                return;
            }

            remove (source);
            insert (source, new_position);
            current = dnd_media (old_position, new_position);
        }
    }
}
