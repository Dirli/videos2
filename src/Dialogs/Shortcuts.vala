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
    public class Dialogs.Shortcuts : Gtk.Dialog {

        public Shortcuts () {
            Object (modal: true,
                    deletable: false,
                    title: _("Keyboard Shortcuts"),
                    destroy_with_parent: true);
        }

        construct {
            set_default_response (Gtk.ResponseType.CANCEL);

            var common_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            common_box.valign = Gtk.Align.CENTER;
            common_box.add (new Granite.AccelLabel (_("Show me"), "<Control>s"));
            common_box.add (new Granite.AccelLabel (_("Show preferences"), "<Control>p"));
            common_box.add (new Granite.AccelLabel (_("Open"), "<Control>o"));
            common_box.add (new Granite.AccelLabel (_("Add"), "<Control><Shift>o"));
            common_box.add (new Granite.AccelLabel (_("Clear"), "<Control>w"));
            common_box.add (new Granite.AccelLabel (_("Exit"), "<Control>q"));
            common_box.add (new Granite.AccelLabel (_("Save & Exit"), "<Control><Shift>q"));
            common_box.add (new Granite.AccelLabel (_("Fullscreen"), "f"));
            common_box.add (new Granite.AccelLabel (_("Show/Hide playlist"), "<Control>l"));
            common_box.add (new Granite.AccelLabel (_("Show info"), "<Control>i"));

            var playback_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            playback_box.valign = Gtk.Align.CENTER;
            playback_box.add (new Granite.AccelLabel (_("Play/Pause"), "space"));
            playback_box.add (new Granite.AccelLabel (_("Stop"), "<Alt>Left"));
            playback_box.add (new Granite.AccelLabel (_("Forward 10 sec"), "Right"));
            playback_box.add (new Granite.AccelLabel (_("Forward 1 min"), "Up"));
            playback_box.add (new Granite.AccelLabel (_("Back 10 sec"), "Left"));
            playback_box.add (new Granite.AccelLabel (_("Back 1 min"), "Down"));
            playback_box.add (new Granite.AccelLabel (_("Mute"), "m"));
            playback_box.add (new Granite.AccelLabel (_("Volume up"), "<Release>KP_Add"));
            playback_box.add (new Granite.AccelLabel (_("Volume down"), "<Release>KP_Subtract"));
            playback_box.add (new Granite.AccelLabel (_("Speed up"), "<Control><Release>KP_Add"));
            playback_box.add (new Granite.AccelLabel (_("Speed down"), "<Control><Release>KP_Subtract"));

            var shortcuts_stack = new Gtk.Stack ();

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.homogeneous = true;
            stack_switcher.stack = shortcuts_stack;

            shortcuts_stack.add_titled (common_box, "common", _("Common"));
            shortcuts_stack.add_titled (playback_box, "playback", _("Playback"));

            var content = get_content_area () as Gtk.Box;
            var shortcuts_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            shortcuts_box.margin = 12;
            shortcuts_box.add (stack_switcher);
            shortcuts_box.add (shortcuts_stack);

            content.add (shortcuts_box);

            var close_button = add_button (_("Close"), Gtk.ResponseType.CANCEL);
            close_button.grab_focus ();

            response.connect (() => {destroy ();});
        }
    }
}
