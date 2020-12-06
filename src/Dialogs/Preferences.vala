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

            var library_switch = new Gtk.Switch ();
            library_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("enable-library", library_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var library_filechooser = new Gtk.FileChooserButton (_("Select Video Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);
            library_filechooser.hexpand = true;
            library_filechooser.sensitive = library_switch.active;

            if (library_switch.active) {
                var library_path = main_win.settings.get_string ("library-path");
                if (library_path == "") {
                    var default_library = GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS);
                    if (default_library != null) {
                        library_path = default_library;
                    }
                }

                if (library_path != "") {
                    library_filechooser.set_current_folder (library_path);
                }
            }

            library_filechooser.notify["sensitive"].connect (() => {
                if (library_filechooser.sensitive) {
                    var default_library = GLib.Environment.get_user_special_dir (GLib.UserDirectory.VIDEOS);
                    if (default_library != null) {
                        library_filechooser.set_current_folder (default_library);
                        main_win.settings.set_string ("library-path", default_library);
                    }
                } else {
                    main_win.settings.set_string ("library-path", "");
                }
            });
            library_filechooser.file_set.connect (() => {
                string? filename = library_filechooser.get_filename ();
                if (filename != null) {
                    main_win.settings.set_string ("library-path", filename);
                }
            });

            library_switch.notify["active"].connect (() => {
                library_filechooser.sensitive = library_switch.active;
            });

            var sleep_mode_switch = new Gtk.Switch ();
            sleep_mode_switch.halign = Gtk.Align.START;
            main_win.settings.bind ("block-sleep-mode", sleep_mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var categories_btn = new Gtk.SpinButton.with_range (0, 10, 1);
            categories_btn.halign = Gtk.Align.END;
            categories_btn.set_width_chars (4);
            main_win.settings.bind ("categories-count", categories_btn, "value", SettingsBindFlags.DEFAULT);

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

            layout.attach (new SettingsLabel (_("Video library")), 0, top);
            layout.attach (library_switch, 1, top++);
            layout.attach (library_filechooser, 0, top++, 2, 1);

            layout.attach (new SettingsLabel (_("Categories count")), 0, top);
            layout.attach (categories_btn, 1, top++);

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
