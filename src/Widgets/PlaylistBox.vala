namespace Videos2 {
    public class Widgets.PlaylistBox : Gtk.ListBox {
        // public signal void play (GLib.File path);
        // public signal void stop_video ();
        public signal int dnd_media (int old_position, int new_position);

        private int current = -1;

        // ~PlaylistBox () {
        //     save_playlist ();
        // }

        public PlaylistBox () {
            Object (can_focus: true,
                    expand: true,
                    activate_on_single_click: false,
                    selection_mode: Gtk.SelectionMode.BROWSE);
        }

        construct {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, Constants.TARGET_ENTRIES, Gdk.DragAction.MOVE);
            drag_data_received.connect (on_drag_data_received);

            // Automatically load from gsettings last_played_videos
            // restore_playlist ();
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

        // private void restore_playlist () {
        //     current = 0;
        //
        //     for (int i = 0; i < settings.get_strv ("last-played-videos").length; i++) {
        //         if (settings.get_strv ("last-played-videos")[i] == settings.get_string ("current-video"))
        //             current = i;
        //         add_item (GLib.File.new_for_uri (settings.get_strv ("last-played-videos")[i]));
        //     }
        // }

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
