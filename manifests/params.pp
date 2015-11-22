#
# = Class: redmine::params
#
# This class provides defaults for apcuspd and redmine::web classes
#
class redmine::params {
  $ensure           = 'present'
  $version          = undef
  $status           = 'enabled'
  $file_mode        = '0644'
  $file_owner       = 'root'
  $file_group       = 'root'

  $dependency_class = 'redmine::dependency'
  $my_class         = undef

  # install package depending on major version
  case $::osfamily {
    default: {}
    /(RedHat|redhat|amazon)/: {
      $package           = 'redmine'
    }
    /(debian|ubuntu)/: {
    }
  }

}
