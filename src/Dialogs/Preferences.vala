namespace Videos2 {
    public class Dialogs.Preferences : Gtk.Dialog {
        public Preferences (Videos2.MainWindow main_win) {
            Object (
                border_width: 6,
                deletable: false,
                destroy_with_parent: true,
                resizable: false,
                title: _("Preferences"),
                transient_for: main_win,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );

            set_default_response (Gtk.ResponseType.CLOSE);

            var vaapi_switch = new Gtk.Switch ();
            vaapi_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("use-vaapi", vaapi_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var sleep_mode_switch = new Gtk.Switch ();
            sleep_mode_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("block-sleep-mode", sleep_mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var layout = new Gtk.Grid ();
            layout.column_spacing = 12;
            layout.margin = 6;
            layout.row_spacing = 6;

            layout.attach (new SettingsLabel (_("Use vaapi:")), 0, 0);
            layout.attach (vaapi_switch, 1, 0);
            layout.attach (new SettingsLabel (_("Block sleep mode")), 0, 1);
            layout.attach (sleep_mode_switch, 1, 1);

            var content = get_content_area () as Gtk.Box;
            content.add (layout);

            add_button (_("Close"), Gtk.ResponseType.CLOSE);

            response.connect (() => {destroy ();});
            show_all ();
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label = text;
                halign = Gtk.Align.END;
                hexpand = true;
                margin_start = 12;
            }
        }
    }
}
