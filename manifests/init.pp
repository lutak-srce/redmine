#
# = Class: redmine
#
# This class manages RedMine
#
#
# == Parameters
#
# [*ensure*]
#   Type: string, default: 'present'
#   Manages package installation and class resources. Possible values:
#   * 'present' - Install package, ensure files are present (default)
#   * 'absent'  - Stop service and remove package and managed files
#
# [*package*]
#   Type: string, default on $::osfamily basis
#   Manages the name of the package.
#
# [*version*]
#   Type: string, default: undef
#   If this value is set, the defined version of package is installed.
#   Possible values are:
#   * 'x.y.z' - Specific version
#   * latest  - Latest available
#
# [*file_mode*]
# [*file_owner*]
# [*file_group*]
#   Type: string, default: '0600'
#   Type: string, default: 'root'
#   Type: string, default 'root'
#   File permissions and ownership information assigned to config files.
#
# [*file_apcupsd_conf*]
#   Type: string, default on $::osfamily basis
#   Path to apcuspd.conf.
#
# [*my_class*]
#   Type: string, default: undef
#   Name of a custom class to autoload to manage module's customizations
#
# [*noops*]
#   Type: boolean, default: undef
#   Set noop metaparameter to true for all the resources managed by the module.
#   If true no real change is done is done by the module on the system.
#
# [*db_adapter*]
#   Type: string, default: 'postgresql'
#   Defines the database connection adapter used.
#
# [*db_name*]
#   Type: string, default: 'redmine'
#   Name of the database.
#
# [*db_host*]
#   Type: string, default: 'localhost'
#   Database host.
#
# [*db_user*]
#   Type: string, default: 'redmine'
#   Initiate a shutdown if a battery level drops below this value.
#
# [*db_pass*]
#   Type: string, default:
#   Password for database access.
#
# [*db_enc*]
#   Type: string, default: 'utf8'
#   Database encoding.
#
# [*db_schema*]
#   Type: string, default: 'public'
#   Database schema.
#
# [*secret_token*]
#   Type: string, default: undef
#   Token generated by 'rake generate_secret_token'
#
# [*email_delivery*]
#   Type: string, default: :smtp
#   Possible values are: :smtp, :sendmail, :async_smtp, :async_sendmail
#
# [*email_username*]
# [*email_password*]
# [*email_server*]
# [*email_server_port*]
# [*email_domain*]
#   Type: string, default: undef
#   Possible values are: :smtp, :sendmail, :async_smtp, :async_sendmail
#
# [*email_auth*]
#   Type: string, default: undef
#   Possible values are: :plain, :login, :cram_md5
#
# [*configuration_template*]
#   Type: string, default: redmine/configration.yaml.erb
#   Location of a template for RedMine's configuration.yml
#
# [*additional_env*]
#   Type: hash, default: {}
#   Hash containing additional environment stuff.
#
class redmine (
  $ensure            = $::redmine::params::ensure,
  $package           = $::redmine::params::package,
  $version           = $::redmine::params::version,
  $file_mode         = $::redmine::params::file_mode,
  $file_owner        = $::redmine::params::file_owner,
  $file_group        = $::redmine::params::file_group,
  $dependency_class  = $::redmine::params::dependency_class,
  $my_class          = $::redmine::params::my_class,
  $noops             = undef,
  $db_adapter        = 'postgresql',
  $db_name           = 'redmine',
  $db_host           = 'localhost',
  $db_user           = 'redmine',
  $db_pass           = '',
  $db_enc            = 'utf8',
  $db_schema         = 'public',
  $secret_token      = undef,
  $email_delivery    = ':smtp',
  $email_username    = undef,
  $email_password    = undef,
  $email_server      = undef,
  $email_server_port = undef,
  $email_domain      = undef,
  $email_auth        = undef,
  $config_template   = 'redmine/configuration.yml.erb',
  $additional_env    = {},
) inherits redmine::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($package)
  validate_string($version)
  validate_re($secret_token, '^[[:alnum:]]+$', 'Please define secret_token as alphanumerics.')
  validate_re($email_delivery, [':smtp',':sendmail',':async_smtp',':async_sendmail'], 'Valid values are: :smtp, :sendmail, :async_smtp, :async_sendmail')
  validate_re($email_auth, ['^$', ':plain', ':login', ':cram_md5'], 'Valid values are: :plain, :login, :cram_md5')

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $file_ensure = present
  } else {
    $package_ensure = absent
    $file_ensure    = absent
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  # choose correct package
  case $db_adapter {
    postgresql: { $db_package = 'pg' }
    mysql:      { $db_package = 'mysql' }
    mysql2:     { $db_package = 'mysql' }
    sqlite:     { $db_package = 'sqlite' }
    sqlserver:  { fail('SQLserver not supported as RedMine backend yet') }
    default:    { fail('Unrecognized database backend for RedMine') }
  }

  package { 'redmine-db':
    ensure => $version,
    name   => "${package}-${db_package}",
    noop   => $noops,
  }

  package { 'redmine':
    ensure  => $package_ensure,
    name    => $package,
    require => Package['redmine-db'],
    noop    => $noops,
  }

  # set defaults for file resource in this scope.
  File {
    ensure  => $file_ensure,
    owner   => $file_owner,
    group   => $file_group,
    mode    => $file_mode,
    noop    => $noops,
  }

  file { '/etc/redmine/database.yml':
    group   => apache,
    mode    => '0640',
    content => template('redmine/database.yml.erb'),
    require => Package['redmine'],
  }

  file { '/etc/redmine/initializers/secret_token.rb':
    group   => apache,
    mode    => '0640',
    content => template('redmine/secret_token.erb'),
    require => Package['redmine'],
  }

  file { '/etc/redmine/configuration.yml':
    group   => apache,
    mode    => '0640',
    content => template($config_template),
    require => Package['redmine'],
  }

  file { '/etc/redmine/additional_environment.rb':
    content => template('redmine/additional_environment.erb'),
    require => Package['redmine'],
  }


}
# vi:syntax=puppet:filetype=puppet:ts=4:et:nowrap:
