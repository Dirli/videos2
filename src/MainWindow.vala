namespace Videos2 {
    public class MainWindow : Gtk.Window {
        private bool show_volume_info = false;
        private bool has_vaapi;

        private Objects.Playlist playlist;

        public GLib.Settings settings;
        private Services.Inhibitor inhibitor;
        private Services.DiskManager disk_manager;

        private Gtk.Stack main_stack;
        private Views.WelcomePage welcome_page;

        private uint current_h = 0;
        private uint current_w = 0;

        private Widgets.Player player;
        private Widgets.HeadBar header_bar;
        private Widgets.TopBar top_bar;
        private Widgets.InfoBar info_bar;
        private Widgets.BottomBar bottom_bar;

        private bool _fullscreened = false;
        public bool fullscreened {
            get {
                return _fullscreened;
            }
            set {
                _fullscreened = value;
                if (value && bottom_bar.child_revealed) {
                    top_bar.reveal_child = true;
                // } else if (!value && bottom_bar.child_revealed) {
                } else {
                    top_bar.reveal_child = false;
                }
            }
        }

        private Enums.MediaType _media_type;
        public Enums.MediaType media_type {
            get {
                return _media_type;
            }
            set {
                if (_media_type != value) {
                    _media_type = value;

                    bottom_bar.playlist_visible = value == Enums.MediaType.VIDEO;
                }
            }
        }

        private const ActionEntry[] ACTION_ENTRIES = {
            { Constants.ACTION_QUIT, action_quit, "b" },
            { Constants.ACTION_OPEN, action_open },
            { Constants.ACTION_ADD, action_add },
            { Constants.ACTION_BACK, action_back },
            { Constants.ACTION_CLEAR, action_clear },
            { Constants.ACTION_MEDIAINFO, action_mediainfo },
            { Constants.ACTION_VOLUME, action_volume, "b" },
            { Constants.ACTION_PLAYLIST_VISIBLE, action_playlist_visible },
            // { Constants.ACTION_SEARCH, action_search }
        };

        public MainWindow (Gtk.Application app) {
            Object (window_position: Gtk.WindowPosition.CENTER,
                    gravity: Gdk.Gravity.CENTER,
                    application: app,
                    title: _("Videos"));

            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_BACK, {"<Alt>Left"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_CLEAR, {"<Control>w"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_PLAYLIST_VISIBLE, {"<Control>l"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_QUIT + "(false)", {"<Control>q"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_QUIT + "(true)", {"<Control><Shift>q"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_OPEN, {"<Control>o"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_MEDIAINFO, {"<Control>i"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_ADD, {"<Control><Shift>o"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_VOLUME + "(true)", {"<Release>KP_Add"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_VOLUME + "(false)", {"<Release>KP_Subtract"});
            // application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_SEARCH, {"<Control>f"});

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/videos2/style/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        construct {
            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            set_default_size (960, 540);

            settings = new GLib.Settings (Constants.APP_NAME);
            inhibitor = new Services.Inhibitor (this);
            disk_manager = new Services.DiskManager ();

            playlist = new Objects.Playlist ();

            build_ui ();

            settings.bind ("block-sleep-mode", inhibitor, "allow-block", GLib.SettingsBindFlags.DEFAULT);

            playlist.play_media.connect ((uri, index) => {
                play_uri (Enums.MediaType.VIDEO, uri);
                welcome_page.update_replay_button (uri);
                bottom_bar.playlist_current_item (index);
                settings.set_string ("current-uri", uri);
            });
            playlist.cleared_playlist.connect (() => {
                player.stop ();
                bottom_bar.clear_playlist_box ();
                welcome_page.update_replay_button ("");
                settings.set_string ("current-uri", "");
            });
            playlist.added_item.connect (bottom_bar.add_playlist_item);
            playlist.changed_nav.connect ((first, last) => {
                bottom_bar.change_nav (!first, !last);
            });
            playlist.restore_medias (settings.get_strv ("last-played-videos"), settings.get_string ("current-uri"));

            settings.set_strv ("last-played-videos", {""});
            settings.set_string ("current-uri", "");

            disk_manager.found_media.connect (() => {
                welcome_page.update_media_button (true);
            });
            disk_manager.deleted_media.connect (() => {
                welcome_page.update_media_button (false);
                if (media_type == Enums.MediaType.DVD) {
                    var state = player.get_playbin_state ();
                    if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                        player.stop ();
                    }
                }
            });

            window_state_event.connect ((e) => {
                if (Gdk.WindowState.FULLSCREEN in e.changed_mask) {
                    fullscreened = Gdk.WindowState.FULLSCREEN in e.new_window_state;
                    header_bar.visible = !fullscreened;

                    if (!fullscreened) {
                        unmaximize ();
                        if (current_h > 0 && current_w > 0) {
                            resize ((int) current_w, (int) current_h);
                        }
                    }
                }

                if (Gdk.WindowState.MAXIMIZED in e.changed_mask) {
                    bool currently_maximixed = Gdk.WindowState.MAXIMIZED in e.new_window_state;

                    if (main_stack.visible_child_name == "player" && currently_maximixed) {
                       fullscreen ();
                    }
                }

                return false;
            });

            Gtk.TargetEntry uris = {"text/uri-list", 0, 0};
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {uris}, Gdk.DragAction.MOVE);
            drag_data_received.connect ((ctx, x, y, sel, info, time) => {
                var files = new GLib.Array<GLib.File> ();
                foreach (var uri in sel.get_uris ()) {
                    var file = GLib.File.new_for_uri (uri);
                    files.append_val (file);
                }

                open_files (files.data, player.get_playbin_state () == Gst.State.PLAYING ? false : true);
            });
        }

        private void build_ui () {
            welcome_page = new Views.WelcomePage ();
            welcome_page.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        action_open ();
                        break;
                    case 1:
                        if (!resume_last_videos ()) {
                            welcome_page.update_replay_button ("");
                        }
                        break;
                    case 2:
                        if (!run_open_dvd ()) {
                            welcome_page.update_media_button (false);
                        }
                        break;
                }
            });

            header_bar = new Widgets.HeadBar ();
            header_bar.navigation_clicked.connect (action_back);
            header_bar.show_preferences.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });

            set_titlebar (header_bar);

            unowned Gst.Registry registry = Gst.Registry.@get ();

            var find_vaapi = registry.find_plugin ("vaapi");
            if (!settings.get_boolean ("use-vaapi")) {
                if (find_vaapi != null) {
                    registry.remove_plugin (find_vaapi);
                }

                has_vaapi = false;
            } else {
                has_vaapi = find_vaapi != null;
            }

            player = new Widgets.Player (has_vaapi);
            header_bar.audio_selected.connect (player.set_active_audio);
            header_bar.subtitle_selected.connect (player.set_active_subtitle);

            top_bar = new Widgets.TopBar ();
            top_bar.unfullscreen.connect (() => {
                unfullscreen ();
            });

            info_bar = new Widgets.InfoBar (has_vaapi);

            bottom_bar = new Widgets.BottomBar ();
            bottom_bar.notify["reveal-child"].connect (() => {
                if (bottom_bar.reveal_child == true && fullscreened == true) {
                    top_bar.reveal_child = true;
                } else if (bottom_bar.reveal_child == false) {
                    top_bar.reveal_child = false;
                }
            });


            player.playbin_state_changed.connect ((state) => {
                inhibitor.playback_state = state;
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    bottom_bar.playing = (state == Gst.State.PLAYING);

                    if (is_maximized) {
                        fullscreen ();
                    }

                    // inhibitor.inhibit ();
                } else {
                    title = _("Videos");
                    if (fullscreened) {
                        unfullscreen ();
                    }
                    main_stack.set_visible_child_name ("welcome");

                    // inhibitor.uninhibit ();
                }
            });
            player.motion_notify_event.connect ((event) => {
                bottom_bar.reveal_control ();
                return false;
            });
            player.duration_changed.connect (bottom_bar.change_duration);
            player.progress_changed.connect (bottom_bar.change_progress);
            player.uri_changed.connect ((uri) => {
                if (uri != "") {
                    if (media_type == Enums.MediaType.DVD) {
                        title = "DVD";
                        header_bar.clear_meta ();
                    } else {
                        title = Utils.get_title (uri);
                        header_bar.setup_uri_meta (uri);
                    }
                } else {
                    header_bar.clear_meta ();
                    title = _("Videos");
                }
            });
            player.audio_changed.connect (header_bar.set_active_audio);
            player.ended_stream.connect (() => {
                if (!playlist.next ()) {
                    player.stop ();
                }
            });
            player.toggled_fullscreen.connect (() => {
                if (fullscreened) {
                    unfullscreen ();
                } else {
                    fullscreen ();
                }
            });

            bottom_bar.play_toggled.connect (player.toggle_playing);
            bottom_bar.seeked.connect (player.seek_jump_value);
            bottom_bar.select_media.connect (playlist.select_media);
            bottom_bar.clear_media.connect (playlist.clear_media);
            bottom_bar.dnd_media.connect (playlist.change_media_position);
            bottom_bar.play_next.connect (playlist.next);
            bottom_bar.play_prev.connect (playlist.previous);
            bottom_bar.volume_changed.connect ((val) => {
                player.volume = val;
                settings.set_double ("volume", val);
                if (show_volume_info) {
                    info_bar.show_volume (val);
                }

                show_volume_info = false;
            });
            bottom_bar.volume_value = settings.get_double ("volume");

            var player_page = new Gtk.Overlay ();
            player_page.add (player);
            player_page.add_overlay (bottom_bar);
            player_page.add_overlay (top_bar);
            player_page.add_overlay (info_bar);

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            main_stack.add_named (welcome_page, "welcome");
            main_stack.add_named (player_page, "player");

            main_stack.show_all ();
            main_stack.notify["visible-child-name"].connect (on_changed_child);

            add (main_stack);

            main_stack.set_visible_child_name ("welcome");
            welcome_page.update_replay_button (settings.get_string ("current-uri"));
            welcome_page.update_media_button (disk_manager.has_media_mounts);
        }

        private void action_open () {
            var files = Utils.run_file_chooser (this);
            if (files.length > 0) {
                open_files (files, true);
            }
        }

        private void action_add () {
            var files = Utils.run_file_chooser (this);
            if (files.length > 0) {
                open_files (files, player.get_playbin_state () == Gst.State.PLAYING ? false : true);
            }
        }

        private void action_quit (GLib.SimpleAction action, GLib.Variant? pars) {
            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                player.stop ();
            }

            bool save_current_state;
            pars.@get ("b", out save_current_state);
            if (!save_current_state) {
                settings.set_string ("current-uri", "");
            } else {
                save_playlist ();
            }

            destroy ();
        }

        private void action_back () {
            if (main_stack.get_visible_child_name () != "welcome") {
                var state = player.get_playbin_state ();
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    player.stop ();
                }
            }
        }

        private void action_playlist_visible () {
            if (main_stack.get_visible_child_name () == "player") {
                bottom_bar.toggle_playlist ();
            }
        }

        private void action_volume (GLib.SimpleAction action, GLib.Variant? pars) {
            if (main_stack.get_visible_child_name () == "player") {
                show_volume_info = true;
                bool vol_value;
                pars.@get ("b", out vol_value);
                bottom_bar.volume_value = vol_value ? 0.05 : -0.05;
            }
        }

        private void action_mediainfo () {
            if (main_stack.get_visible_child_name () == "player" && media_type == Enums.MediaType.VIDEO) {
                var uri = playlist.get_uri ();
                if (uri == "") {
                    return;
                }

                var discoverer_info = Utils.get_discoverer_info (uri);
                if (discoverer_info != null) {
                    var media_info = "";

                    media_info += Utils.prepare_video_info (discoverer_info);
                    media_info += Utils.prepare_audio_info (discoverer_info);
                    media_info += Utils.prepare_sub_info (discoverer_info);

                    info_bar.show_media_info (media_info);
                }
            }
        }

        private void action_clear () {
            if (media_type == Enums.MediaType.VIDEO) {
                playlist.clear_media (-1);
            }
        }

        private void on_changed_child () {
            var view_name = main_stack.get_visible_child_name ();
            header_bar.navigation_visible = (view_name != "welcome");

            switch (view_name) {
                case "welcome":
                    resize (960, 540);
                    break;
                case "player":
                    //
                    break;
            }
        }

        private bool run_open_dvd () {
            unowned string root_uri = disk_manager.mount_uri;
            if (root_uri == "") {
                return false;
            }

            play_uri (Enums.MediaType.DVD, root_uri.replace ("file:///", "dvd:///"));
            return true;
        }

        public void open_files (GLib.File[] files, bool clear) {
            if (clear) {
                action_clear ();
            }

            header_bar.navigation_label = Constants.NAV_BUTTON_WELCOME;

            string filename;
            string content_type;
            foreach (GLib.File file in files) {
                if (!Utils.check_media (file, out filename, out content_type)) {
                    var unsupported_file = new Dialogs.UnsupportedFile (this, file.get_uri (), filename, content_type);

                    unsupported_file.response.connect (type => {
                        if (type == Gtk.ResponseType.ACCEPT) {
                            playlist.add_media (file, true);
                        }

                        unsupported_file.destroy ();
                    });

                    // for some reason, blocking seems more appropriate here
                    unsupported_file.show_all ();
                    unsupported_file.run ();
                } else {
                    playlist.add_media (file, true);
                }
            }
        }

        private void play_uri (Enums.MediaType m_type, string uri) {
            Utils.get_video_size (uri, out current_w, out current_h);

            media_type = m_type;

            if (current_h > 0 && current_w > 0) {
                resize ((int) current_w, (int) current_h);
            }

            main_stack.set_visible_child_name ("player");

            player.set_uri (uri);
        }

        public override bool key_press_event (Gdk.EventKey e) {
            switch (e.keyval) {
                case Gdk.Key.Escape:
                    if (main_stack.get_visible_child_name () == "player" && fullscreened) {
                        unfullscreen ();
                        return true;
                    }
                    break;
                case Gdk.Key.space:
                    if (main_stack.get_visible_child_name () == "player") {
                        player.toggle_playing ();
                        return true;
                    } else if (main_stack.get_visible_child_name () == "welcome") {
                        resume_last_videos ();
                        return true;
                    }

                    break;
                case Gdk.Key.f:
                    if (main_stack.get_visible_child_name () == "player") {
                        if (fullscreened) {
                            unfullscreen ();
                        } else {
                            fullscreen ();
                        }
                        return true;
                    }
                    break;
                case Gdk.Key.m:
                    if (main_stack.get_visible_child_name () == "player") {
                        bottom_bar.volume_sensitive = !player.toggle_mute ();
                        return true;
                    }
                    break;
                case Gdk.Key.Up:
                case Gdk.Key.Down:
                case Gdk.Key.Left:
                case Gdk.Key.Right:
                    if (main_stack.get_visible_child_name () == "player" && (e.state & Gdk.ModifierType.MOD1_MASK) == 0) {
                        player.seek_jump_seconds (e.keyval == Gdk.Key.Up ? 60 :
                                                  e.keyval == Gdk.Key.Down ? -60 :
                                                  e.keyval == Gdk.Key.Left ? -10 :
                                                  10);

                        bottom_bar.reveal_control ();
                        return true;
                    }

                    break;
            }

            return base.key_press_event (e);
        }

        private bool resume_last_videos () {
            var last_played = playlist.current;
            if (last_played > -1) {
                header_bar.navigation_label = Constants.NAV_BUTTON_WELCOME;
                playlist.current = last_played;
                return true;
            }

            return false;
        }

        public bool is_privacy_mode_enabled () {
            var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");

            if (!privacy_settings.get_boolean ("remember-recent-files") || !privacy_settings.get_boolean ("remember-app-usage")) {
                return true;
            }

            return false;
        }

        public void save_playlist () {
            if (is_privacy_mode_enabled ()) {
                return;
            }

            var uris = playlist.get_medias ();
            settings.set_strv ("last-played-videos", uris);
        }

        public override bool delete_event (Gdk.EventAny event) {
            save_playlist ();

            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                player.stop ();
            }

            return false;
        }
    }
}
