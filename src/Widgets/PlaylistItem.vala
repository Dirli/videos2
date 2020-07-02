namespace Videos2 {
    public class Widgets.PlaylistItem : Gtk.ListBoxRow {
        public bool is_playing { get; set; }

        public string title { get; construct; }
        public string uri { get; construct; }

        public PlaylistItem (string title, string uri) {
            Object (title: title,
                    uri: uri);
        }

        construct {
            var play_icon = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.BUTTON);

            var play_revealer = new Gtk.Revealer ();
            play_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            play_revealer.add (play_icon);

            var track_name_label = new Gtk.Label (title);
            track_name_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_bottom = grid.margin_top = 6;
            grid.column_spacing = 6;
            grid.add (play_revealer);
            grid.add (track_name_label);

            // Drag source must have a GdkWindow. GTK4 will remove the limitation.
            var dnd_event_box = new Gtk.EventBox ();
            dnd_event_box.drag_begin.connect (on_drag_begin);
            dnd_event_box.drag_data_get.connect (on_drag_data_get);
            dnd_event_box.add (grid);

            Gtk.drag_source_set (dnd_event_box, Gdk.ModifierType.BUTTON1_MASK, Constants.TARGET_ENTRIES, Gdk.DragAction.MOVE);

            set_tooltip_text (title);

            add (dnd_event_box);
            show_all ();

            bind_property ("is-playing", play_revealer, "reveal-child");
        }

        private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
            var row = (Widgets.PlaylistItem) widget.get_ancestor (typeof (Widgets.PlaylistItem));

            Gtk.Allocation alloc;
            row.get_allocation (out alloc);

            var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
            var cr = new Cairo.Context (surface);
            row.draw (cr);

            int x, y;
            widget.translate_coordinates (row, 0, 0, out x, out y);
            surface.set_device_offset (-x, -y);
            Gtk.drag_set_icon_surface (context, surface);
        }

        private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
            uchar[] data = new uchar[(sizeof (Widgets.PlaylistItem))];
            ((Gtk.Widget[]) data)[0] = widget;

            selection_data.set (Gdk.Atom.intern_static_string ("PLAYLIST_ITEM"), 32, data);
        }
    }
}
