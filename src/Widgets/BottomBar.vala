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
    public class Widgets.BottomBar : Gtk.Revealer {
        public signal void play_toggled ();
        public signal bool play_next ();
        public signal bool play_prev ();
        public signal void stop_playback ();
        public signal void seeked (int64 val);
        public signal void select_media (string uri);
        public signal bool clear_media (int index);
        public signal void volume_changed (double val);
        public signal void repeat_changed (bool repeate_node);
        public signal void audio_selected (int i);
        public signal void speed_selected (int i);
        public signal void subtitle_selected (int i);
        public signal int dnd_media (int old_position, int new_position);

        private uint hiding_timer = 0;
        private uint preview_timer = 0;

        public Widgets.PlaylistBox playlist_box;

        public Gtk.ToggleButton repeat_button;

        private Gtk.Button prev_button;
        private Gtk.Button stop_button;
        private Gtk.Button play_button;
        private Gtk.Button next_button;
        private Gtk.VolumeButton volume_button;
        private Gtk.MenuButton playlist_button;
        private Gtk.MenuButton menu_button;

        private Gtk.Popover playlist_popover;
        private Gtk.Popover menu_popover;
        private Widgets.PreviewPopover? preview_popover;

        private Granite.SeekBar time_bar;

        private Gtk.ComboBoxText audio_streams;
        private Gtk.ComboBoxText sub_streams;
        private Gtk.ComboBoxText speed_list;

        private bool playlist_glowing = false;
        private bool playlist_need_close = false;

        private string _uri;
        public string uri {
            get {
                return _uri;
            }
            set {
                _uri = value;
                if (value != "") {
                    setup_uri_meta (value);
                } else {
                    clear_meta ();
                }

                destroy_preview ();
            }
        }

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

        public bool show_preview {
            set {
                if (value) {
                    time_bar.scale.motion_notify_event.connect (on_motion_notify_event);
                    time_bar.scale.leave_notify_event.connect (on_leave_notify_event);
                } else {
                    time_bar.scale.motion_notify_event.disconnect (on_motion_notify_event);
                    time_bar.scale.leave_notify_event.disconnect (on_leave_notify_event);
                }
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
        }

        construct {
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
            create_controls ();

            // time bar
            time_bar = new Granite.SeekBar (0.0);
            time_bar.scale.vexpand = true;
            time_bar.scale.change_value.connect (on_change_value);

            // volume
            volume_button = new Gtk.VolumeButton ();
            volume_button.value_changed.connect ((val) => {
                volume_changed (val);
            });

            create_playlist ();

            create_menu ();

            var main_actionbar = new Gtk.ActionBar ();

            main_actionbar.pack_start (prev_button);
            main_actionbar.pack_start (stop_button);
            main_actionbar.pack_start (next_button);
            main_actionbar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
            main_actionbar.pack_start (play_button);
            main_actionbar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
            main_actionbar.set_center_widget (time_bar);
            main_actionbar.pack_end (menu_button);
            main_actionbar.pack_end (playlist_button);
            main_actionbar.pack_end (volume_button);
            main_actionbar.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));

            add (main_actionbar);
        }

        private void create_controls () {
            prev_button = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic", Gtk.IconSize.BUTTON);
            prev_button.tooltip_text = _("Previous");
            prev_button.clicked.connect (() => {
                if (!play_prev ()) {
                    prev_button.sensitive = false;
                }
            });

            stop_button = new Gtk.Button.from_icon_name ("media-playback-stop-symbolic", Gtk.IconSize.BUTTON);
            stop_button.tooltip_text = _("Stop");
            stop_button.clicked.connect (() => {
                stop_playback ();
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
        }

        private void create_playlist () {
            var add_button = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
            add_button.set_action_name (Constants.ACTION_PREFIX + Constants.ACTION_ADD);
            add_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control><Shift>o"}, _("Open file"));
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
            repeat_button.set_image (new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic",
                                                                   Gtk.IconSize.BUTTON));
            repeat_button.tooltip_text = _("Enable Repeat");
            repeat_button.toggled.connect (() => {
                repeat_button.set_tooltip_text (repeat_button.active ? _("Disable Repeat") : _("Enable Repeat"));
                repeat_button.set_image (new Gtk.Image.from_icon_name (repeat_button.active ?
                                                                       "media-playlist-repeat-symbolic" :
                                                                       "media-playlist-no-repeat-symbolic",
                                                                       Gtk.IconSize.BUTTON));

                repeat_changed (repeat_button.active);
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
        }

        private void create_menu () {
            var audio_label = new Gtk.Label (_("Audio:"));
            audio_label.halign = Gtk.Align.END;

            audio_streams = new Gtk.ComboBoxText ();
            audio_streams.append ("none", _("None"));
            audio_streams.sensitive = false;

            var sub_label = new Gtk.Label (_("Subtitles:"));
            sub_label.halign = Gtk.Align.END;

            sub_streams = new Gtk.ComboBoxText ();
            sub_streams.append ("none", _("None"));
            sub_streams.sensitive = false;

            var speed_label = new Gtk.Label (_("Speed:"));
            speed_label.halign = Gtk.Align.END;

            speed_list = new Gtk.ComboBoxText ();
            for (var i = 0; i < Constants.speeds_array.length; i++) {
                speed_list.append (@"$(i)", @"$(Constants.speeds_array[i])x");
            }

            int top = 0;
            var menu_grid = new Gtk.Grid ();
            menu_grid.column_spacing = 12;
            menu_grid.row_spacing = 6;
            menu_grid.margin = 6;
            menu_grid.attach (audio_label, 0, top);
            menu_grid.attach (audio_streams, 1, top++);
            menu_grid.attach (sub_label, 0, top);
            menu_grid.attach (sub_streams, 1, top++);
            menu_grid.attach (speed_label, 0, top);
            menu_grid.attach (speed_list, 1, top++);

            var pref_button = new Gtk.ModelButton ();
            pref_button.text = _("Preferences");
            pref_button.set_action_name (Constants.ACTION_PREFIX + Constants.ACTION_PREFERENCES);

            var about_button = new Gtk.ModelButton ();
            about_button.text = _("About");
            about_button.clicked.connect (() => {
                var about = new Dialogs.About ();
                about.run ();
            });

            var shortcuts_button = new Gtk.ModelButton ();
            shortcuts_button.text = _("Keyboard shortcuts");
            shortcuts_button.set_action_name (Constants.ACTION_PREFIX + Constants.ACTION_SHORTCUTS);

            menu_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, top++, 2, 1);
            menu_grid.attach (pref_button, 0, top++, 2, 1);
            menu_grid.attach (shortcuts_button, 0, top++, 2, 1);
            menu_grid.attach (about_button, 0, top++, 2, 1);
            menu_grid.show_all ();

            menu_popover = new Gtk.Popover (null);
            menu_popover.add (menu_grid);

            menu_button = new Gtk.MenuButton ();
            menu_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            menu_button.popover = menu_popover;
            menu_button.valign = Gtk.Align.CENTER;

            audio_streams.changed.connect (on_audio_changed);
            sub_streams.changed.connect (on_subtitles_changed);
            speed_list.changed.connect (on_speed_changed);
        }

        private void on_audio_changed () {
            if (audio_streams.active < 0 || audio_streams.active_id == "def" || audio_streams.active_id == "none") {
                return;
            }

            audio_selected (audio_streams.active);
        }

        private void on_speed_changed () {
            if (speed_list.active < 0) {
                return;
            }

            speed_selected (speed_list.active);
        }

        private void on_subtitles_changed () {
            if (sub_streams.active < 0) {
                return;
            }

            subtitle_selected (sub_streams.active_id == "none" ? -1 : sub_streams.active);
        }

        private bool on_leave_notify_event (Gdk.EventCrossing e) {
            destroy_preview ();

            return false;
        }

        private bool on_motion_notify_event (Gdk.EventMotion event) {
            if (uri == "") {
                return false;
            }

            if (preview_timer > 0) {
                GLib.Source.remove (preview_timer);
                preview_timer = 0;
            }

            preview_timer = GLib.Timeout.add (800, () => {
                preview_timer = 0;

                if (preview_popover == null) {
                    preview_popover = new Widgets.PreviewPopover (uri);
                    preview_popover.set_relative_to (time_bar.scale);
                }

                preview_popover.update_view (event.x, event.window.get_width ());

                return false;
            });

            return false;
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

        public bool on_change_value (Gtk.ScrollType scroll, double val) {
            int64 new_position = Utils.sec_to_nano ((int64) (val * time_bar.playback_duration));
            seeked (new_position);

            return false;
        }

        private void destroy_preview () {
            if (preview_timer > 0) {
                GLib.Source.remove (preview_timer);
                preview_timer = 0;
            }

            if (preview_popover != null) {
                preview_popover.stop_watch ();
                preview_popover.destroy ();
                preview_popover = null;
            }
        }

        public void set_active_speed (int active_speed) {
            if (active_speed < 0 || active_speed == speed_list.active) {
                return;
            }

            speed_list.changed.disconnect (on_speed_changed);
            speed_list.active = active_speed;
            speed_list.changed.connect (on_speed_changed);
        }

        public void set_active_audio (int active_index) {
            if (active_index == audio_streams.active || active_index == -1) {
                return;
            }

            audio_streams.changed.disconnect (on_audio_changed);
            audio_streams.active = active_index;
            audio_streams.changed.connect (on_audio_changed);
        }

        public void clear_meta () {
            audio_streams.changed.disconnect (on_audio_changed);
            if (audio_streams.model.iter_n_children (null) > 0) {
                audio_streams.remove_all ();
            }

            audio_streams.sensitive = false;
            audio_streams.changed.connect (on_audio_changed);

            sub_streams.changed.disconnect (on_subtitles_changed);
            if (sub_streams.model.iter_n_children (null) > 0) {
                sub_streams.remove_all ();
            }

            sub_streams.sensitive = false;
            sub_streams.changed.connect (on_subtitles_changed);
        }

        public void setup_uri_meta (string uri) {
            var discoverer_info = Utils.get_discoverer_info (uri);
            if (discoverer_info != null) {
                audio_streams.changed.disconnect (on_audio_changed);
                if (audio_streams.model.iter_n_children (null) > 0) {
                    audio_streams.remove_all ();
                }

                setup_audio (discoverer_info);

                audio_streams.changed.connect (on_audio_changed);

                sub_streams.changed.disconnect (on_subtitles_changed);

                if (sub_streams.model.iter_n_children (null) > 0) {
                    sub_streams.remove_all ();
                }

                int none_index = setup_subtitles (discoverer_info);

                sub_streams.changed.connect (on_subtitles_changed);
                sub_streams.active = none_index;
            }
        }

        private void setup_audio (Gst.PbUtils.DiscovererInfo discoverer_info) {
            var a_streams = discoverer_info.get_audio_streams ();

            if (a_streams.length () > 1) {
                int track = 1;
                foreach (var stream_info in a_streams) {
                    var audio_stream = stream_info as Gst.PbUtils.DiscovererAudioInfo;
                    if (audio_stream != null) {
                        unowned string language_code = audio_stream.get_language ();

                        if (language_code != null) {
                            unowned string language_name = Gst.Tag.get_language_name (language_code);
                            audio_streams.prepend ("", language_name);
                        } else {
                            audio_streams.prepend ("", _("Track '%u'").printf (track));
                        }
                    }

                    track++;
                }
            } else {
                audio_streams.append ("def", _("Default"));
                audio_streams.active = 0;
            }

            audio_streams.sensitive = a_streams.length () > 1;
        }

        private int setup_subtitles (Gst.PbUtils.DiscovererInfo discoverer_info) {
            var s_streams = discoverer_info.get_subtitle_streams ();
            int track = 1;
            foreach (var stream_info in s_streams) {
                var sub_stream = stream_info as Gst.PbUtils.DiscovererSubtitleInfo;
                if (sub_stream != null) {
                    unowned string language_code = sub_stream.get_language ();
                    if (language_code != null) {
                        unowned string language_name = Gst.Tag.get_language_name (language_code);
                        sub_streams.prepend ("", language_name);
                    } else {
                        sub_streams.prepend ("", _("Track '%u'").printf (track));
                    }
                }

                track++;
            }

            sub_streams.append ("none", _("None"));
            sub_streams.sensitive = s_streams.length () > 0;

            return (int) s_streams.length ();
        }

        public void next_audio () {
            int count = audio_streams.model.iter_n_children (null);
            if (count > 0) {
                audio_streams.active = (audio_streams.active + 1) % count;
            }
        }

        public void next_subtitles () {
            int count = sub_streams.model.iter_n_children (null);
            if (count > 0) {
                sub_streams.active = (sub_streams.active + 1) % count;
            }
        }

        public void toggle_playlist () {
            if (playlist_popover.visible) {
                playlist_need_close = false;

                playlist_popover.popdown ();
            } else {
                playlist_need_close = true;

                reveal_control ();
                playlist_popover.popup ();
            }
        }

        public void change_nav (bool can_prev, bool can_next) {
            prev_button.sensitive = can_prev;
            next_button.sensitive = can_next;

            if (!can_next && !can_prev) {
                prev_button.visible = false;
                next_button.visible = false;
            } else {
                prev_button.visible = true;
                next_button.visible = true;
            }
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
                hiding_timer = 0;

                if (playlist_need_close) {
                    playlist_need_close = false;

                    playlist_popover.popdown ();

                    return false;
                }

                if (hovered ||
                    playlist_popover.visible ||
                    menu_popover.visible ||
                    volume_button.get_popup ().visible ||
                    !playing) {

                    return false;
                }

                set_reveal_child (false);

                return false;
            });
        }
    }
}
