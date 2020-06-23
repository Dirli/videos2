namespace Videos2 {
    public class MainWindow : Gtk.Window {

        private Gtk.Stack main_stack;
        private Views.WelcomePage welcome_page;

        private Widgets.Player player;
        private Widgets.BottomBar bottom_bar;

        private const ActionEntry[] ACTION_ENTRIES = {
            { Constants.ACTION_OPEN, action_open },
            // { Constants.ACTION_SEARCH, action_search }
        };

        public MainWindow (Gtk.Application app) {
            Object (window_position: Gtk.WindowPosition.CENTER,
                    gravity: Gdk.Gravity.CENTER,
                    application: app,
                    title: _("Videos"));

            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_OPEN, {"<Control>o"});
            // application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_SEARCH, {"<Control>f"});
        }

        construct {
            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            set_default_size (1000, 680);

            build_ui ();
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

            player = new Widgets.Player ();
            bottom_bar = new Widgets.BottomBar ();

            player.playbin_state_changed.connect ((state) => {
                if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                    bottom_bar.playing = (state == Gst.State.PLAYING);
                }
            });
            player.motion_notify_event.connect ((event) => {
                bottom_bar.reveal_control ();
                return false;
            });
            player.duration_changed.connect ((d) => {
                bottom_bar.change_duration (d);
            });
            player.progress_changed.connect ((p) => {
                bottom_bar.change_progress (p);
            });
            player.uri_changed.connect ((uri) => {
                if (uri != "") {
                    title = Utils.get_title (uri);
                }
            });

            bottom_bar.play_toggled.connect (() => {
                player.toggle_playing ();
            });
            bottom_bar.seeked.connect ((seek_value) => {
                player.seek_jump_percent (seek_value);
            });


            var player_page = new Gtk.Overlay ();
            player_page.add (player);
            player_page.add_overlay (bottom_bar);

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            main_stack.add_named (welcome_page, "welcome");
            main_stack.add_named (player_page, "player");

            main_stack.notify["visible-child-name"].connect (on_changed_child);

            add (main_stack);
            show_all ();
        }

        public void action_open () {
            var files = Utils.run_file_chooser ();
            if (files.length > 0) {
                open_files (files);
            }
        }

        private void on_changed_child () {
            var view_name = main_stack.get_visible_child_name ();

            switch (view_name) {
                case "welcome":
                    //
                    break;
                case "player":
                    //
                    break;
            }
        }

        public void open_files (GLib.File[] files) {
            main_stack.set_visible_child_name ("player");
            player.set_uri (files[0].get_uri ());
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

        public override bool delete_event (Gdk.EventAny event) {
            player.stop ();

            return false;
        }
    }
}
