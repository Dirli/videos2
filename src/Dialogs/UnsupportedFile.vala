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
    public class Dialogs.UnsupportedFile : Granite.MessageDialog {
        public string content_type { get; construct; }
        public string uri { get; construct; }

        public UnsupportedFile (Gtk.Window window, string uri, string filename, string content_type) {
            Object (title: "",
                    primary_text: _("Unrecognized file format"),
                    secondary_text: _("Videos might not be able to play the file '%s'.".printf (filename)),
                    buttons: Gtk.ButtonsType.CANCEL,
                    image_icon: new ThemedIcon ("dialog-error"),
                    transient_for: window,
                    window_position: Gtk.WindowPosition.CENTER,
                    content_type: content_type,
                    uri: uri);
        }

        construct {
            var play_anyway_button = add_button (_("Play Anyway"), Gtk.ResponseType.ACCEPT);
            play_anyway_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            play_anyway_button.is_focus = true;

            var error_text = _("Unable to play file at: '%s'\nThe file is not a video ('%s').").printf (
                uri,
                GLib.ContentType.get_description (content_type)
            );
            show_error_details (error_text);
        }
    }
}
