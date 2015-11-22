#
# = Class: redmine::dependency
#
# This class lists dependencies for class redmine
#
class redmine::dependency {
  include ::yum::repo::epel
  include ::yum::repo::srce::test
  include ::ruby::gems
  include ::ruby::gem::rails
}
