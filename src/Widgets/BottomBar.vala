namespace Videos2 {
    public class Widgets.BottomBar : Gtk.Revealer {
        public signal void play_toggled ();
        public signal bool play_next ();
        public signal bool play_prev ();
        public signal void seeked (int64 val);
        public signal void select_media (string uri);
        public signal bool clear_media (int index);
        public signal void volume_changed (double val);
        public signal int dnd_media (int old_position, int new_position);

        private uint hiding_timer = 0;

        public Widgets.PlaylistBox playlist_box;

        public Gtk.ToggleButton repeat_button;

        private Gtk.Button prev_button;
        private Gtk.Button play_button;
        private Gtk.Button next_button;
        private Gtk.VolumeButton volume_button;
        private Gtk.MenuButton playlist_button;
        private Gtk.Popover playlist_popover;
        private Granite.SeekBar time_bar;


        private bool playlist_glowing = false;

        private bool _hovered = false;
        private bool hovered {
            get {
                return _hovered;
            }
            set {
                _hovered = value;
                if (value) {
                    if (hiding_timer != 0) {
                        GLib.Source.remove (hiding_timer);
                        hiding_timer = 0;
                    }
                } else {
                    reveal_control ();
                }
            }
        }

        public double volume_value {
            set {
                var new_value = volume_button.get_value () + value;
                volume_button.set_value (new_value > 1.0 ? 1.0 :
                                         new_value < 0.0 ? 0.0 :
                                         new_value);
            }
        }

        public bool volume_sensitive {
            set {
                volume_button.sensitive = value;
            }
        }

        public bool playlist_visible {
            set {
                playlist_button.visible = value; 
            }
        }

        private bool _playing = false;
        public bool playing {
            get {
                return _playing;
            }
            set {
                _playing = value;

                play_button.tooltip_text = value ? _("Pause") : _("Play");
                ((Gtk.Image) play_button.image).icon_name = value ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";

                if (value) {
                    reveal_control ();
                } else {
                    set_reveal_child (true);
                }
            }
        }

        public BottomBar () {
            Object (valign: Gtk.Align.END);

            events |= Gdk.EventMask.POINTER_MOTION_MASK;
            events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            events |= Gdk.EventMask.ENTER_NOTIFY_MASK;

            transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

            init_events ();
            build_ui ();
        }

        private void init_events () {
            enter_notify_event.connect ((event) => {
                if (event.window == get_window ()) {
                    hovered = true;
                }

                return false;
            });

            leave_notify_event.connect ((event) => {
                if (event.window == get_window ()) {
                    hovered = false;
                }

                return false;
            });
        }

        private void build_ui () {
            // control button
            prev_button = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic", Gtk.IconSize.BUTTON);
            prev_button.tooltip_text = _("Previous");
            prev_button.clicked.connect (() => {
                if (!play_prev ()) {
                    prev_button.sensitive = false;
                }
            });

            play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
            play_button.tooltip_text = _("Play");
            play_button.clicked.connect (() => {
                play_toggled ();
            });

            next_button = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic", Gtk.IconSize.BUTTON);
            next_button.tooltip_text = _("Next");
            next_button.clicked.connect (() => {
                if (!play_next ()) {
                    next_button.sensitive = false;
                }
            });

            // time bar
            time_bar = new Granite.SeekBar (0.0);
            time_bar.scale.vexpand = true;
            time_bar.scale.change_value.connect (on_change_value);
            // volume
            volume_button = new Gtk.VolumeButton ();
            volume_button.value_changed.connect ((val) => {
                volume_changed (val);
            });
            // playlist
            var add_button = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
            add_button.set_action_name (Constants.ACTION_PREFIX + Constants.ACTION_ADD);
            add_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control><Shift>o"}, _("Open file "));
            add_button.clicked.connect (() => {
                playlist_popover.popdown ();
            });

            var clear_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
            clear_button.set_action_name (Constants.ACTION_PREFIX + Constants.ACTION_CLEAR);
            clear_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control>w"}, _("Clear Playlist"));
            clear_button.clicked.connect (() => {
                playlist_popover.popdown ();
            });

            Gtk.drag_dest_set (clear_button, Gtk.DestDefaults.ALL, Constants.TARGET_ENTRIES, Gdk.DragAction.MOVE);
            clear_button.drag_data_received.connect (on_drag_data_received);

            repeat_button = new Gtk.ToggleButton ();
            repeat_button.set_image (new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic", Gtk.IconSize.BUTTON));
            repeat_button.tooltip_text = _("Enable Repeat");
            repeat_button.toggled.connect (() => {
                repeat_button.set_tooltip_text (repeat_button.active ? _("Disable Repeat") : _("Enable Repeat"));
                repeat_button.set_image (new Gtk.Image.from_icon_name (repeat_button.active ? "media-playlist-repeat-symbolic" : "media-playlist-no-repeat-symbolic", Gtk.IconSize.BUTTON));
            });

            playlist_box = new Widgets.PlaylistBox ();
            playlist_box.row_activated.connect ((item) => {
                var selected_item = item as Widgets.PlaylistItem;
                if (selected_item != null) {
                    select_media (selected_item.uri);
                }
            });
            playlist_box.dnd_media.connect ((old_position, new_position) => {
                return dnd_media (old_position, new_position);
            });

            var playlist_scrolled = new Gtk.ScrolledWindow (null, null);
            playlist_scrolled.min_content_height = 100;
            playlist_scrolled.max_content_height = 400;
            playlist_scrolled.min_content_width = 260;
            playlist_scrolled.propagate_natural_height = true;
            playlist_scrolled.add (playlist_box);

            var playlist_grid = new Gtk.Grid ();
            playlist_grid.row_spacing = playlist_grid.margin = 6;
            playlist_grid.column_spacing = 12;

            playlist_grid.attach (playlist_scrolled, 0, 0, 4, 1);
            playlist_grid.attach (add_button, 0, 1);
            playlist_grid.attach (clear_button, 1, 1);
            playlist_grid.attach (repeat_button, 3, 1);
            playlist_grid.show_all ();

            playlist_popover = new Gtk.Popover (null);
            playlist_popover.opacity = Constants.GLOBAL_OPACITY;
            playlist_popover.add (playlist_grid);
            playlist_popover.closed.connect (() => {
                reveal_control ();
            });

            playlist_button = new Gtk.MenuButton ();
            playlist_button.image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.BUTTON);
            playlist_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control>l"}, _("Playlist"));
            playlist_button.valign = Gtk.Align.CENTER;
            playlist_button.popover = playlist_popover;

            var main_actionbar = new Gtk.ActionBar ();

            main_actionbar.pack_start (prev_button);
            main_actionbar.pack_start (play_button);
            main_actionbar.pack_start (next_button);
            main_actionbar.set_center_widget (time_bar);
            main_actionbar.pack_end (playlist_button);
            main_actionbar.pack_end (volume_button);

            add (main_actionbar);
        }

        private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
            Gtk.Widget row = ((Gtk.Widget[]) selection_data.get_data ())[0];

            var source = row.get_ancestor (typeof (Widgets.PlaylistItem));
            if (source == null) {
                return;
            }

            var playlist_item = source as Widgets.PlaylistItem;
            if (playlist_item == null || playlist_item.is_playing) {
                return;
            }

            var item_index = playlist_item.get_index ();

            if (clear_media (item_index)) {
                playlist_box.remove (playlist_item);
            }
        }

        public virtual bool on_change_value (Gtk.ScrollType scroll, double val) {
            int64 new_position = Utils.sec_to_nano ((int64) (val * time_bar.playback_duration));
            seeked (new_position);

            return false;
        }

        public void toggle_playlist () {
            if (playlist_popover.visible) {
                playlist_popover.popdown ();
            } else {
                reveal_control ();
                playlist_popover.popup ();
            }
        }

        public void change_nav (bool can_prev, bool can_next) {
            prev_button.sensitive = can_prev;
            next_button.sensitive = can_next;
        }

        public void change_duration (int64 dur) {
            time_bar.playback_duration = (double) dur / Gst.SECOND;
            change_progress (0);
        }

        public void change_progress (int64 prog) {
            if (!time_bar.is_grabbing) {
                time_bar.playback_progress = ((double) prog / Gst.SECOND) / time_bar.playback_duration;
            }
        }

        public void clear_playlist_box () {
            playlist_box.set_current (-1);
            foreach (Gtk.Widget item in playlist_box.get_children ()) {
                playlist_box.remove (item);
            }
        }

        public void playlist_current_item (int index) {
            playlist_box.set_current (index);
        }

        public void add_playlist_item (string uri, string basename) {
            var row = new Widgets.PlaylistItem (Utils.get_title (basename), uri);
            playlist_box.add (row);

            if (!playlist_glowing) {
                playlist_glowing = true;
                var playlist_style_context = playlist_button.get_child ().get_style_context ();
                playlist_style_context.add_class (Constants.PULSE_CLASS);
                playlist_style_context.add_class (Constants.PULSE_TYPE);

                GLib.Timeout.add (6000, () => {
                    playlist_style_context.remove_class (Constants.PULSE_CLASS);
                    playlist_style_context.remove_class (Constants.PULSE_TYPE);
                    playlist_glowing = false;

                    return false;
                });
            }
        }

        public void reveal_control () {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            hiding_timer = GLib.Timeout.add (2000, () => {
                if (hovered || playlist_popover.visible || volume_button.get_popup ().visible || !playing) {
                    hiding_timer = 0;

                    return false;
                }
                set_reveal_child (false);
                hiding_timer = 0;

                return false;
            });
        }
    }
}
