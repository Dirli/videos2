conf_data = configuration_data ()
conf_data.set ('EXEC_PATH', join_paths (get_option ('prefix'), get_option ('bindir'), meson.project_name ()))

icon_sizes = ['16', '24', '32', '48', '64', '128']

data_dir = join_paths (get_option ('prefix'), get_option ('datadir'))
icon_dir = join_paths (data_dir, 'icons', 'hicolor')

foreach i : icon_sizes
    install_data (
        join_paths ('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths (icon_dir, i + 'x' + i, 'apps')
    )
endforeach

configure_file (
    input: meson.project_name () + '.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install_dir: dep_dbus.get_pkgconfig_variable ('session_bus_services_dir')
)

install_data (
    meson.project_name () + '.gschema.xml',
    install_dir: join_paths (data_dir, 'glib-2.0', 'schemas')
)

install_data (
    meson.project_name () + '.desktop',
    install_dir: join_paths (data_dir, 'applications'),
)

gresource = gnome.compile_resources (
    'as-resources',
    join_paths (meson.project_name () + '.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)
