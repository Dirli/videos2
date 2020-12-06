namespace Videos2 {
    public class MainWindow : Gtk.Window {
        private bool show_volume_info = false;

        private Objects.Player player;
        private Objects.Playlist playlist;

        public GLib.Settings settings;
        private Services.Inhibitor inhibitor;
        private Services.DiskManager disk_manager;
        private Services.LibraryManager library_manager;
        private Services.RestoreManager? restore_manager;

        private Gtk.Stack main_stack;
        private Views.WelcomePage welcome_page;
        private Views.LibraryPage library_page;

        private Gtk.DrawingArea video_area;

        private uint owner_id = 0;
        public Services.MprisProxy? mpris_proxy = null;

        private uint current_h = 0;
        private uint current_w = 0;
        private uint cursor_timer = 0;

        private Gtk.Button restore_button;
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
                top_bar.reveal_child = value && bottom_bar.child_revealed;

                if (!value) {
                    show_mouse_cursor ();
                } else {
                    hide_mouse_cursor ();
                }
            }
        }

        private uint _restore_id;
        public uint restore_id {
            get {
                return _restore_id;
            }
            set {
                if (restore_id > 0) {
                    GLib.Source.remove (restore_id);
                }

                _restore_id = value;

                if (value == 0) {
                    if (restore_manager != null) {
                        restore_manager.reset ();
                    }
                }

                restore_button.visible = value > 0;
            }
        }

        private Enums.MediaType _media_type = Enums.MediaType.NONE;
        public Enums.MediaType media_type {
            get {
                return _media_type;
            }
            set {
                if (_media_type != value) {
                    _media_type = value;

                    bottom_bar.playlist_visible = value <= Enums.MediaType.LIBRARY;
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
            changed_remember_time ();

            inhibitor = new Services.Inhibitor (this);
            mpris_proxy = new Services.MprisProxy ();
            disk_manager = new Services.DiskManager ();
            library_manager = new Services.LibraryManager (settings.get_int ("categories-count"));

            player = new Objects.Player ();
            playlist = new Objects.Playlist ();

            build_ui ();

            try {
                owner_id = GLib.Bus.own_name (GLib.BusType.SESSION,
                                              Constants.MPRIS_NAME,
                                              GLib.BusNameOwnerFlags.NONE,
                                              on_bus_acquired,
                                              null,
                                              null);
            } catch (Error e) {
                warning ("could not create MPRIS player: %s\n", e.message);
                mpris_proxy = null;
            }

            settings.bind ("block-sleep-mode", inhibitor, "allow-block", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("library-path", library_manager, "root-path", GLib.SettingsBindFlags.GET);

            changed_library_path ();

            settings.changed["remember-time"].connect (changed_remember_time);
            settings.changed["library-path"].connect (changed_library_path);
            settings.changed["categories-count"].connect (changed_categories_count);

            player.duration_changed.connect (bottom_bar.change_duration);
            player.progress_changed.connect (bottom_bar.change_progress);
            player.audio_changed.connect (bottom_bar.set_active_audio);
            player.playbin_state_changed.connect ((state) => {
                inhibitor.playback_state = state;
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    bottom_bar.playing = (state == Gst.State.PLAYING);

                    if (is_maximized) {
                        fullscreen ();
                    }
                } else {
                    if (fullscreened) {
                        unfullscreen ();
                    }

                    // if () {
                        main_stack.set_visible_child_name ("welcome");
                    // } else if () {
                    //     main_stack.set_visible_child_name ("library");
                    // }
                }

                if (mpris_proxy != null) {
                    mpris_proxy.state = state;
                }
            });
            player.uri_changed.connect (on_uri_changed);
            player.ended_stream.connect (() => {
                if (!playlist.next ()) {
                    player.stop ();
                }
            });

            playlist.play_media.connect ((uri, index) => {
                if (media_type == Enums.MediaType.NONE) {
                    media_type = Enums.MediaType.VIDEO;
                }
                play_uri (uri);
                welcome_page.update_replay_button (uri);
                bottom_bar.playlist_current_item (index);
                settings.set_string ("current-uri", uri);
            });
            playlist.cleared_playlist.connect (() => {
                player.stop ();
            });
            playlist.added_item.connect (bottom_bar.add_playlist_item);
            playlist.changed_nav.connect ((first, last) => {
                bottom_bar.change_nav (!first, !last);
                if (mpris_proxy != null) {
                    mpris_proxy.can_next = !last;
                    mpris_proxy.can_previous = !first;
                }
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

            library_manager.item_found.connect (library_page.add_item);
            library_manager.parents_found.connect (header_bar.add_lib_path);
            library_manager.notify["current-uri"].connect (changed_current_catagory);

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
                    case 3:
                        main_stack.set_visible_child_name ("library");
                        break;

                }
            });

            header_bar = new Widgets.HeadBar ();

            top_bar = new Widgets.TopBar ();
            top_bar.unfullscreen.connect (() => {
                unfullscreen ();
            });

            info_bar = new Widgets.InfoBar (false);

            bottom_bar = new Widgets.BottomBar ();
            bottom_bar.audio_selected.connect (player.set_active_audio);
            bottom_bar.subtitle_selected.connect (player.set_active_subtitle);
            bottom_bar.play_toggled.connect (player.toggle_playing);
            bottom_bar.select_media.connect (playlist.select_media);
            bottom_bar.clear_media.connect (playlist.clear_media);
            bottom_bar.dnd_media.connect (playlist.change_media_position);
            bottom_bar.play_next.connect (playlist.next);
            bottom_bar.play_prev.connect (playlist.previous);
            bottom_bar.stop_playback.connect (action_back);
            bottom_bar.volume_changed.connect (on_volume_changed);
            bottom_bar.notify["reveal-child"].connect (() => {
                if (bottom_bar.reveal_child == true && fullscreened == true) {
                    top_bar.reveal_child = true;
                } else if (bottom_bar.reveal_child == false) {
                    top_bar.reveal_child = false;
                }
            });
            bottom_bar.show_preferences.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });
            bottom_bar.seeked.connect ((pos) => {
                player.seek_jump_value (pos);
                if (restore_id > 0) {
                    restore_id = 0;
                }
            });

            bottom_bar.volume_value = settings.get_double ("volume");

            video_area = new Gtk.DrawingArea ();
            video_area.events |= Gdk.EventMask.POINTER_MOTION_MASK;
            video_area.realize.connect (on_realize_video);
            video_area.draw.connect (on_draw_video);

            var video_box = new Gtk.EventBox ();
            video_box.add (video_area);
            video_box.motion_notify_event.connect ((event) => {
                bottom_bar.reveal_control ();
                if (fullscreened && cursor_timer == 0) {
                    show_mouse_cursor ();
                }
                return false;
            });
            video_box.button_press_event.connect ((event) => {
                if (event.button == Gdk.BUTTON_SECONDARY) {
                    player.toggle_playing ();
                    return true;
                }

                if (event.button == Gdk.BUTTON_PRIMARY && event.type == Gdk.EventType.2BUTTON_PRESS) {
                    if (fullscreened) {
                        unfullscreen ();
                    } else {
                        fullscreen ();
                    }

                    return true;
                }

                return base.button_press_event (event);
            });

            restore_button = new Gtk.Button ();
            restore_button.label = _("Continue");
            restore_button.valign = Gtk.Align.START;
            restore_button.halign = Gtk.Align.START;
            restore_button.margin = 10;
            restore_button.clicked.connect (on_restore_clicked);

            var player_page = new Gtk.Overlay ();
            player_page.add (video_box);
            player_page.add_overlay (bottom_bar);
            player_page.add_overlay (top_bar);
            player_page.add_overlay (info_bar);
            player_page.add_overlay (restore_button);

            library_page = new Views.LibraryPage ();
            library_page.select_category.connect (on_select_category);

            library_page.select_media.connect ((uri) => {
                action_clear ();

                media_type = Enums.MediaType.LIBRARY;

                playlist.add_media (GLib.File.new_for_uri (uri), true);
            });

            header_bar.select_category.connect (on_select_category);

            main_stack = new Gtk.Stack ();

            main_stack.add_named (welcome_page, "welcome");
            main_stack.add_named (player_page, "player");
            main_stack.add_named (library_page, "library");
            add (main_stack);
            show_all ();

            restore_button.visible = false;

            main_stack.notify["visible-child-name"].connect (on_changed_child);
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
            bool save_current_state;
            pars.@get ("b", out save_current_state);

            save_current_state = save_current_state && !is_privacy_mode_enabled ();

            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                if (save_current_state) {
                    save_current_position (true);
                }

                player.stop ();
            }

            if (!save_current_state) {
                settings.set_string ("current-uri", "");
            } else {
                save_playlist ();
            }

            destroy ();
        }
        private void action_back () {
            var v_child = main_stack.get_visible_child_name ();

            if (v_child == "player") {
                var state = player.get_playbin_state ();
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    save_current_position (false);

                    player.stop ();
                }
            } else if (v_child == "library") {
                main_stack.set_visible_child_name ("welcome");
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
            if (main_stack.get_visible_child_name () == "player" && media_type <= Enums.MediaType.LIBRARY) {
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
            media_type = Enums.MediaType.NONE;

            playlist.clear_media (-1);

            bottom_bar.clear_playlist_box ();
            welcome_page.update_replay_button ("");
            settings.set_string ("current-uri", "");
        }

        private void on_bus_acquired (DBusConnection connection, string name) {
            try {
                mpris_proxy.play.connect (player.play);
                mpris_proxy.stop.connect (player.stop);
                mpris_proxy.pause.connect (player.pause);
                mpris_proxy.next.connect (playlist.next);
                mpris_proxy.prev.connect (playlist.previous);
                mpris_proxy.toggle_playing.connect (player.toggle_playing);

                connection.register_object (Constants.MPRIS_PATH, new Objects.MprisRoot ());
                connection.register_object (Constants.MPRIS_PATH, new Objects.MprisPlayer (connection, mpris_proxy));
            } catch (IOError e) {
                warning ("could not create MPRIS player: %s\n", e.message);
            }
        }

        private void on_realize_video () {
            var win = video_area.get_window ();
            if (!win.ensure_native ()) {
                return;
            }

            player.set_win_xid (((Gdk.X11.Window) win).get_xid ());
        }

        private bool on_draw_video (Cairo.Context ctx) {
            if (player.get_playbin_state () < Gst.State.PAUSED) {
                Gtk.Allocation allocation;
                video_area.get_allocation (out allocation);

                ctx.set_source_rgb (0, 0, 0);
                ctx.rectangle (0, 0, allocation.width, allocation.height);
                ctx.fill ();
            }

            return false;
        }

        private void on_uri_changed (string uri) {
            if (uri != "") {
                if (media_type == Enums.MediaType.DVD) {
                    title = "DVD";
                    bottom_bar.clear_meta ();
                } else {
                    title = Utils.get_title (uri);
                    bottom_bar.setup_uri_meta (uri);
                }
            } else {
                bottom_bar.clear_meta ();
            }

            mpris_proxy.title = uri != "" ? title : _("Videos2");
        }

        private void on_volume_changed (double val) {
            player.volume = val;
            settings.set_double ("volume", val);
            if (show_volume_info) {
                info_bar.show_volume (val);
            }

            show_volume_info = false;
        }

        private void on_changed_child () {
            var view_name = main_stack.get_visible_child_name ();

            header_bar.library_button_visible = view_name == "library";

            switch (view_name) {
                case "welcome":
                    resize (960, 540);
                    title = _("Videos");
                    break;
                case "player":
                    //
                    break;
                case "library":
                    resize (960, 540);
                    changed_current_catagory ();
                    on_select_category ("");
                    break;
            }
        }

        private void on_restore_clicked () {
            if (player.get_playbin_state () == Gst.State.PLAYING && restore_button.visible) {
                var pos = restore_manager.restore_position;
                restore_id = 0;

                if (media_type > Enums.MediaType.LIBRARY) {
                    return;
                }

                if (pos > 0) {
                    player.seek_jump_value (pos);
                }
            }
        }

        private void on_select_category (string uri) {
            library_page.clear_box ();
            // TODO there must be something here that doesn't block the flow
            library_manager.init (uri);
        }

        private void changed_remember_time () {
            if (settings.get_boolean ("remember-time")) {
                if (restore_manager == null) {
                    restore_manager = new Services.RestoreManager ();
                }
            } else {
                if (restore_manager != null) {
                    restore_manager.clear_cache ();
                }
                restore_manager = null;
            }
        }

        private void changed_library_path () {
            if (settings.get_string ("library-path") == "") {
                if (main_stack.get_visible_child_name () == "library") {
                    main_stack.set_visible_child_name ("welcome");
                }

                welcome_page.update_library_button (false);
            } else {
                welcome_page.update_library_button (true);
            }
        }

        private void changed_current_catagory () {
            if (main_stack.get_visible_child_name () != "library") {
                return;
            }

            var uri = library_manager.current_uri;
            if (uri != "") {
                var cat_name = GLib.File.new_for_uri (uri).get_basename ();
                if (cat_name != null) {
                    title = cat_name;
                    return;
                }
            }

            title = _("Videos");
        }

        private void changed_categories_count () {
            library_manager.categories_count = settings.get_int ("categories-count");

            if (main_stack.get_visible_child_name () != "library") {
                return;
            }

            on_select_category ("");
        }

        private bool run_open_dvd () {
            unowned string root_uri = disk_manager.mount_uri;
            if (root_uri == "") {
                return false;
            }

            media_type = Enums.MediaType.DVD;

            play_uri (root_uri.replace ("file:///", "dvd:///"));
            return true;
        }

        public void open_files (GLib.File[] files, bool clear) {
            if (clear) {
                action_clear ();
            }

            media_type = Enums.MediaType.VIDEO;

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

        private void play_uri (string uri) {
            Utils.get_video_size (uri, out current_w, out current_h);

            if (current_h > 0 && current_w > 0) {
                resize ((int) current_w, (int) current_h);
            }

            if (main_stack.get_visible_child_name () != "player") {
                main_stack.set_visible_child_name ("player");
            }

            player.set_uri (uri);
            player.play ();

            if (restore_id > 0) {
                restore_id = 0;
            }

            if (media_type <= Enums.MediaType.LIBRARY) {
                if (restore_manager != null && restore_manager.pull (uri)) {
                    restore_id = GLib.Timeout.add (10000, () => {
                        _restore_id = 0;
                        restore_id = 0;

                        return false;
                    });
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

        private void hide_mouse_cursor () {
            var cursor = new Gdk.Cursor.for_display (get_window ().get_display (), Gdk.CursorType.BLANK_CURSOR);
            get_window ().set_cursor (cursor);
        }

        private void show_mouse_cursor () {
            if (cursor_timer != 0) {
                GLib.Source.remove (cursor_timer);
                cursor_timer = 0;
            }

            get_window ().set_cursor (null);
            if (fullscreened) {
                cursor_timer = GLib.Timeout.add (4000, () => {
                    if (fullscreened && bottom_bar.child_revealed) {
                        return true;
                    }

                    hide_mouse_cursor ();
                    cursor_timer = 0;

                    return false;
                });
            }
        }

        private void save_current_position (bool synchronously) {
            if (media_type <= Enums.MediaType.LIBRARY && restore_manager != null) {
                int64 current_position = player.position;
                if (synchronously) {
                    restore_manager.push (settings.get_string ("current-uri"), current_position);
                } else {
                    restore_manager.push_async (settings.get_string ("current-uri"), current_position);
                }
            }
        }

        public bool save_playlist () {
            if (is_privacy_mode_enabled ()) {
                return true;
            }

            var uris = playlist.get_medias ();
            settings.set_strv ("last-played-videos", uris);

            return false;
        }

        public override bool delete_event (Gdk.EventAny event) {
            bool privacy = save_playlist ();

            if (owner_id > 0) {
                GLib.Bus.unown_name (owner_id);
            }

            if (player.get_playbin_state () == Gst.State.PLAYING || player.get_playbin_state () == Gst.State.PAUSED) {
                if (!privacy) {
                    save_current_position (true);
                }

                player.stop ();
            }

            return false;
        }
    }
}
