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
