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
    public class Views.WelcomePage : Granite.Widgets.Welcome {
        private Granite.Widgets.WelcomeButton replay_button;

        public WelcomePage () {
            Object (
                title: _("No Videos Open"),
                subtitle: _("Select a source to begin playing.")
            );
        }

        construct {
            append ("document-open", _("Open file"), _("Open a saved file."));
            append ("media-playlist-repeat", _("Replay last video"), "");
            append ("media-cdrom", _("Play from Disc"), _("Watch a DVD or open a file from disc"));

            replay_button = get_button_from_index (1);
        }

        public void update_media_button (bool show_media) {
            set_item_visible (2, show_media);
        }

        public void update_replay_button (string current_video) {
            bool show_replay_button = false;

            if (current_video != "") {
                var last_file = File.new_for_uri (current_video);
                if (last_file.query_exists () == true) {
                    replay_button.description = Utils.get_title (last_file.get_basename ());

                    show_replay_button = true;
                }
            }

            set_item_visible (1, show_replay_button);
        }

        public void update_replay_title (bool replay) {
            replay_button.title = replay ? _("Replay last video") : _("Resume last video");
            replay_button.icon.icon_name = replay ? "media-playlist-repeat" : "media-playback-start";
        }
    }
}
