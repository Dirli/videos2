project(
    'io.elementary.videos2',
    'vala', 'c',
    version: '0.1.0'
)

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

conf_data = configuration_data()
conf_data.set_quoted('VERSION', meson.project_version())
config_header = configure_file(
    input : 'src/config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants.vala',
    'src/MainWindow.vala',
    'src/Dialogs/About.vala',
    'src/Interfaces/Client.vala',
    'src/Objects/Playlist.vala',
    'src/Services/Inhibitor.vala',
    'src/Services/Utils.vala',
    'src/Views/WelcomePage.vala',
    'src/Widgets/BottomBar.vala',
    'src/Widgets/HeadBar.vala',
    'src/Widgets/Player.vala',
    'src/Widgets/PlaylistBox.vala',
    'src/Widgets/PlaylistItem.vala',
    'src/Widgets/TopBar.vala',
    config_header,
    dependencies: [
        dependency ('gee-0.8'),
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('granite'),
        dependency ('gtk+-3.0', version: '>=3.22'),
        dependency ('gstreamer-1.0'),
        dependency ('gstreamer-pbutils-1.0'),
    ],
    install : true
)

subdir ('data')

meson.add_install_script ('meson_post_install.py')
