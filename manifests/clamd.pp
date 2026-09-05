# @summary Set up clamd config and service.
#
# @param sort_options
#   for true, the options are sorted,
#
class clamav::clamd(
  Boolean $sort_options = true,
) {

  $config_options = $clamav::_clamd_options

  package { 'clamd':
    ensure => $clamav::clamd_version,
    name   => $clamav::clamd_package,
    before => File['clamd.conf'],
  }

  file { 'clamd.conf':
    ensure  => file,
    path    => $clamav::clamd_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/clamav.conf.erb"),
  }

  service { 'clamd':
    ensure     => $clamav::clamd_service_ensure,
    name       => $clamav::clamd_service,
    enable     => $clamav::clamd_service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package['clamd'], File['clamd.conf']],
  }

  # /run/clamav (clamd's LocalSocket directory) is not guaranteed to exist
  # on boot: /run is tmpfs, and the packaged clamd/clamav-daemon service
  # unit ships no RuntimeDirectory= directive. systemd auto-creates
  # $path/clamav owned by the service's User=/Group= before ExecStart and
  # removes it after stop, replacing a hand-rolled ExecStartPre=mkdir/chown.
  $clamd_dropin_dir = "/etc/systemd/system/${clamav::clamd_service}.service.d"

  file { 'clamd_dropin_dir':
    ensure => directory,
    path   => $clamd_dropin_dir,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { 'clamd_runtimedirectory_override':
    ensure  => file,
    path    => "${clamd_dropin_dir}/runtimedirectory.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "[Service]\nRuntimeDirectory=clamav\n",
    require => File['clamd_dropin_dir'],
    notify  => Service['clamd'],
  }
}
