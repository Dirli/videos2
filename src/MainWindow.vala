namespace Videos2 {
    public class MainWindow : Gtk.Window {
        private Objects.Playlist playlist;

        private GLib.Settings settings;
        private Services.Inhibitor inhibitor;

        private Gtk.Stack main_stack;
        private Views.WelcomePage welcome_page;

        private Widgets.Player player;
        private Widgets.HeadBar header_bar;
        private Widgets.TopBar top_bar;
        private Widgets.BottomBar bottom_bar;

        private bool _fullscreened = false;
        public bool fullscreened {
            get {
                return _fullscreened;
            }
            set {
                _fullscreened = value;
                if (value && bottom_bar.child_revealed == true) {
                    top_bar.reveal_child = true;
                } else if (!value && bottom_bar.child_revealed) {
                    top_bar.reveal_child = false;
                }
            }
        }

        private const ActionEntry[] ACTION_ENTRIES = {
            { Constants.ACTION_QUIT, action_quit },
            { Constants.ACTION_OPEN, action_open },
            { Constants.ACTION_ADD, action_add },
            { Constants.ACTION_BACK, action_back },
            { Constants.ACTION_CLEAR, action_clear },
            { Constants.ACTION_JUMP, action_jump, "i" },
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
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_QUIT, {"<Control>q"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_OPEN, {"<Control>o"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_ADD, {"<Control><Shift>o"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_JUMP + "(-10)", {"<Control>Left"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_JUMP + "(10)", {"<Control>Right"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_JUMP + "(-60)", {"<Control>Down"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_JUMP + "(60)", {"<Control>Up"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_VOLUME + "(true)", {"<Release>KP_Add"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_VOLUME + "(false)", {"<Release>KP_Subtract"});
            // application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_SEARCH, {"<Control>f"});
        }

        construct {
            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            set_default_size (960, 540);

            settings = new GLib.Settings (Constants.APP_NAME);
            inhibitor = new Services.Inhibitor (this);

            playlist = new Objects.Playlist ();

            build_ui ();

            playlist.play_media.connect ((uri, index) => {
                main_stack.set_visible_child_name ("player");
                player.set_uri (uri);
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

            window_state_event.connect ((e) => {
                if (Gdk.WindowState.FULLSCREEN in e.changed_mask) {
                    fullscreened = Gdk.WindowState.FULLSCREEN in e.new_window_state;
                    header_bar.visible = !fullscreened;

                    if (!fullscreened) {
                        unmaximize ();
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
                }
            });

            header_bar = new Widgets.HeadBar ();
            header_bar.navigation_clicked.connect (action_back);

            set_titlebar (header_bar);

            player = new Widgets.Player ();
            header_bar.audio_selected.connect (player.set_active_audio);
            header_bar.subtitle_selected.connect (player.set_active_subtitle);

            top_bar = new Widgets.TopBar ();
            top_bar.unfullscreen.connect (() => {
                unfullscreen ();
            });

            bottom_bar = new Widgets.BottomBar ();
            bottom_bar.notify["reveal-child"].connect (() => {
                if (bottom_bar.reveal_child == true && fullscreened == true) {
                    top_bar.reveal_child = true;
                } else if (bottom_bar.reveal_child == false) {
                    top_bar.reveal_child = false;
                }
            });


            player.playbin_state_changed.connect ((state) => {
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    bottom_bar.playing = (state == Gst.State.PLAYING);

                    if (is_maximized) {
                        fullscreen ();
                    }

                    inhibitor.inhibit ();
                } else {
                    title = _("Videos");
                    if (fullscreened) {
                        unfullscreen ();
                    }
                    main_stack.set_visible_child_name ("welcome");

                    inhibitor.uninhibit ();
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
                    title = Utils.get_title (uri);
                    header_bar.setup_uri_meta (uri);
                } else {
                    header_bar.clear_meta ();
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
            });
            bottom_bar.volume_value = settings.get_double ("volume");

            var player_page = new Gtk.Overlay ();
            player_page.add (player);
            player_page.add_overlay (bottom_bar);
            player_page.add_overlay (top_bar);

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

        private void action_quit () {
            player.stop ();
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

        private void action_jump (GLib.SimpleAction action, GLib.Variant? pars) {
            if (main_stack.get_visible_child_name () == "player") {
                int sec_value;
                pars.@get ("i", out sec_value);
                player.seek_jump_seconds (sec_value);
                bottom_bar.reveal_control ();
            }
        }

        private void action_playlist_visible () {
            if (main_stack.get_visible_child_name () == "player") {
                bottom_bar.toggle_playlist ();
            }
        }

        private void action_volume (GLib.SimpleAction action, GLib.Variant? pars) {
            if (main_stack.get_visible_child_name () == "player") {
                bool vol_value;
                pars.@get ("b", out vol_value);
                bottom_bar.volume_value = vol_value ? 0.2 : -0.2;
            }
        }

        private void action_clear () {
            playlist.clear_media (-1);
        }

        private void on_changed_child () {
            var view_name = main_stack.get_visible_child_name ();
            header_bar.navigation_visible = (view_name != "welcome");

            switch (view_name) {
                case "welcome":
                    //
                    break;
                case "player":
                    //
                    break;
            }
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
