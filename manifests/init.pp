# == Class: role_schateiland
#
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_schateiland (
  $compose_version            = '1.17.1',
  $repo_source                = 'https://github.com/naturalis/docker-schateiland.git',
  $repo_ensure                = 'latest',
  $mysql_root_password        = 'rootpassword',
  $repo_dir                   = '/opt/docker-schateiland',
){


  include 'docker'
  include 'stdlib'

  Exec {
    path => '/usr/local/bin/',
    cwd  => $role_schateiland::repo_dir,
  }

  file { "${role_schateiland::repo_dir}/.env":
    ensure   => file,
    mode     => '0600',
    content  => template('role_schateiland/env.erb'),
    require  => Vcsrepo[$role_schateiland::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  class {'docker::compose': 
    ensure      => present,
    version     => $role_schateiland::compose_version,
    notify      => Exec['apt_update']
  }

  ensure_packages(['git','python3'], { ensure => 'present' })

  vcsrepo { $role_schateiland::repo_dir:
    ensure    => $role_schateiland::repo_ensure,
    source    => $role_schateiland::repo_source,
    provider  => 'git',
    user      => 'root',
    revision  => 'master',
    require   => [Package['git'],File[$role_schateiland::repo_dir]]
  }

  docker_compose { "${role_schateiland::repo_dir}/docker-compose.yml":
    ensure      => present,
    require     => [
      Vcsrepo[$role_schateiland::repo_dir],
      File["${role_schateiland::repo_dir}/.env"],
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => Exec['Pull containers']
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => Docker_compose["${role_schateiland::repo_dir}/docker-compose.yml"]
  }

  # deze gaat per dag 1 keer checken
  # je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
  schedule { 'everyday':
     period  => daily,
     repeat  => 1,
     range => '5-7',
  }

}
