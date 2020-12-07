/*
 * Copyright (c) 2020 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

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

            var remember_switch = new Gtk.Switch ();
            remember_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("remember-time", remember_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var sleep_mode_switch = new Gtk.Switch ();
            sleep_mode_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("block-sleep-mode", sleep_mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var layout = new Gtk.Grid ();
            layout.column_spacing = 12;
            layout.margin = 6;
            layout.row_spacing = 6;

            int top = 0;
            layout.attach (new Granite.HeaderLabel (_("Playback preferences")), 0, top++, 2, 1);

            layout.attach (new SettingsLabel (_("Remember stopped time:")), 0, top);
            layout.attach (remember_switch, 1, top++);

            layout.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, top++, 2, 1);

            layout.attach (new Granite.HeaderLabel (_("Desktop Integration")), 0, top++, 2, 1);

            layout.attach (new SettingsLabel (_("Block sleep mode")), 0, top);
            layout.attach (sleep_mode_switch, 1, top++);

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
