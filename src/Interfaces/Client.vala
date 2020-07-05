[DBus (name = "org.freedesktop.ScreenSaver")]
public interface ScreenSaverIface : Object {
    public abstract uint32 inhibit (string app_name, string reason) throws Error;
    public abstract void un_inhibit (uint32 cookie) throws Error;
}
