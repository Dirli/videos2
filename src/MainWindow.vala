namespace Videos2 {
    public class MainWindow : Gtk.Window {
        private Objects.Playlist playlist;

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
            // { Constants.ACTION_SEARCH, action_search }
        };

        public MainWindow (Gtk.Application app) {
            Object (window_position: Gtk.WindowPosition.CENTER,
                    gravity: Gdk.Gravity.CENTER,
                    application: app,
                    title: _("Videos"));

            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_QUIT, {"<Control>q"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_OPEN, {"<Control>o"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_ADD, {"<Control><Shift>o"});
            // application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_SEARCH, {"<Control>f"});
        }

        construct {
            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            set_default_size (800, 680);

            inhibitor = new Services.Inhibitor (this);
            playlist = new Objects.Playlist ();

            build_ui ();

            playlist.play_media.connect ((uri, index) => {
                player.set_uri (uri);
                bottom_bar.playlist_current_item (index);
            });
            playlist.cleared_playlist.connect (() => {
                player.stop ();
                bottom_bar.clear_playlist_box ();
            });
            playlist.added_item.connect (bottom_bar.add_playlist_item);
            playlist.changed_nav.connect ((first, last) => {
                bottom_bar.change_nav (!first, !last);
            });

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
        }

        private void build_ui () {
            welcome_page = new Views.WelcomePage ();
            welcome_page.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        action_open ();
                        break;
                    case 1:
                        //
                        break;
                }
            });

            header_bar = new Widgets.HeadBar ();
            header_bar.navigation_clicked.connect (on_navigation_clicked);

            set_titlebar (header_bar);

            player = new Widgets.Player ();

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
                }
            });
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
        }

        public void action_open () {
            var files = Utils.run_file_chooser ();
            if (files.length > 0) {
                open_files (files);
            }
        }

        public void action_add () {
            var files = Utils.run_file_chooser ();
            if (files.length > 0) {
                open_files (files, false);
            }
        }

        public void action_quit () {
            player.stop ();
            destroy ();
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

        public void on_navigation_clicked (string nav_label) {
            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                player.stop ();
            }
        }

        public void open_files (GLib.File[] files, bool clear = true) {
            playlist.clear_media ();

            main_stack.set_visible_child_name ("player");
            header_bar.navigation_label = Constants.NAV_BUTTON_WELCOME;

            foreach (GLib.File file in files) {
                playlist.add_media (file);
            }
        }

        public override bool key_press_event (Gdk.EventKey e) {
            switch (e.keyval) {
                case Gdk.Key.space:
                    player.toggle_playing ();
                    return true;
                case Gdk.Key.Down:
                    player.seek_jump_seconds (-60);
                    return true;
                case Gdk.Key.Left:
                    player.seek_jump_seconds (-10);
                    return true;
                case Gdk.Key.Right:
                    player.seek_jump_seconds (10);
                    return true;
                case Gdk.Key.Up:
                    player.seek_jump_seconds (60);
                    return true;
            }

            return base.key_press_event (e);
        }

        public bool is_privacy_mode_enabled () {
            var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");

            if (!privacy_settings.get_boolean ("remember-recent-files") || !privacy_settings.get_boolean ("remember-app-usage")) {
                return true;
            }

            return false;
        }

        // public void save_playlist () {
        //     if (is_privacy_mode_enabled ()) {
        //         return;
        //     }
        //
        //     var videos = playlist.get_medias ();
        //     settings.set_strv ("last-played-videos", videos);
        // }

        public override bool delete_event (Gdk.EventAny event) {
            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                player.stop ();
            }

            return false;
        }
    }
}
