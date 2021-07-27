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
    public class Widgets.TopBar : Gtk.Revealer {
        public signal void unfullscreen ();

        public TopBar () {
            Object (transition_type: Gtk.RevealerTransitionType.SLIDE_DOWN,
                    halign: Gtk.Align.END,
                    valign: Gtk.Align.START);
        }

        construct {
            var unfullscreen_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.BUTTON);
            unfullscreen_button.halign = Gtk.Align.END;
            unfullscreen_button.tooltip_text = _("Unfullscreen");
            unfullscreen_button.clicked.connect (() => {
                unfullscreen ();
            });

            add (unfullscreen_button);
        }
    }
}
