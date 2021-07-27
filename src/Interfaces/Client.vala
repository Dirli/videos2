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

[DBus (name = "org.freedesktop.ScreenSaver")]
public interface ScreenSaverIface : Object {
    public abstract uint32 inhibit (string app_name, string reason) throws Error;
    public abstract void un_inhibit (uint32 cookie) throws Error;
}

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
private interface Tumbler : GLib.Object {
    public signal void finished (uint handle);
    public signal void ready (uint handle, string[] uris);
    public abstract async uint queue (string[] uris, string[] mime_types, string flavor, string sheduler, uint handle_to_dequeue) throws GLib.IOError, GLib.DBusError;
}
