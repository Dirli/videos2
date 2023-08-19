project (
  'org.pantheon.videos2',
  'vala', 'c',
  version: '1.0.1'
)

gnome = import ('gnome')
i18n = import ('i18n')

add_global_arguments (
  '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
  language:'c'
)

conf_data = configuration_data ()
conf_data.set ('EXEC_PATH', join_paths (get_option ('prefix'), get_option ('bindir'), meson.project_name ()))
conf_data.set_quoted('VERSION', meson.project_version ())

config_header = configure_file (
  input : 'src/config.vala.in',
  output : 'config.vala',
  configuration : conf_data
)

dep_dbus = dependency ('dbus-1')

subdir ('data')

executable (
  meson.project_name (),
  'src/Application.vala',
  'src/Constants.vala',
  'src/Enums.vala',
  'src/MainWindow.vala',
  'src/Structs.vala',
  'src/Dialogs/About.vala',
  'src/Dialogs/Preferences.vala',
  'src/Dialogs/Shortcuts.vala',
  'src/Dialogs/UnsupportedFile.vala',
  'src/Interfaces/Client.vala',
  'src/Objects/MprisPlayer.vala',
  'src/Objects/MprisRoot.vala',
  'src/Objects/Player.vala',
  'src/Objects/Playlist.vala',
  'src/Services/DiskManager.vala',
  'src/Services/Inhibitor.vala',
  'src/Services/MprisProxy.vala',
  'src/Services/RestoreManager.vala',
  'src/Services/Utils.vala',
  'src/Views/WelcomePage.vala',
  'src/Widgets/BottomBar.vala',
  'src/Widgets/InfoBar.vala',
  'src/Widgets/MovieGrid.vala',
  'src/Widgets/PlaylistBox.vala',
  'src/Widgets/PlaylistItem.vala',
  'src/Widgets/PreviewPopover.vala',
  'src/Widgets/PropsBar.vala',
  'src/Widgets/TopBar.vala',
  config_header,
  gresource,
  dependencies: [
    dependency ('gee-0.8'),
    dependency ('glib-2.0'),
    dependency ('gobject-2.0'),
    dependency ('granite'),
    dependency ('gtk+-3.0', version: '>=3.22'),
    dependency ('gstreamer-1.0', version: '>=1.20'),
    dependency ('gstreamer-tag-1.0'),
    dependency ('gstreamer-base-1.0'),
    dependency ('gstreamer-video-1.0'),
    dependency ('gstreamer-pbutils-1.0'),
  ],
  install : true
)

subdir ('po')

meson.add_install_script ('meson_post_install.py')
