$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'rhoconnect/version'

module Constants
  RC_VERSION      = Rhoconnect::VERSION
  REGION          = 'us-west-1'
  SLEEP           = 60
  HOME_DIR        = `echo ~/`.strip.chomp("/")
  REMOTE_HOME     = '/home/ubuntu'
  PEM_FILE        = 'jenkinskey.pem'
  SSH_KEY         = "#{HOME_DIR}/.ssh/#{PEM_FILE}"
  ACCESS_KEY_FILE = "#{HOME_DIR}/.ec2"
  UBUNTU_STACK    = { :image_id  => 'ami-e0b882a5', # jenkins-ubuntu-14.04-test-image
                      :tags => {'Name' => 'Ubuntu-14.04'},
                      :flavor_id => 'c1.xlarge',
                      :key_name  => 'jenkinskey',
                      :groups    => 'load-test',
                      :user      => 'ubuntu'}
  CENTOS5_STACK   = { :image_id  => 'ami-079b9d42', # jenkins-centos-5.10-test-image
                      :tags => {'Name' => 'CentOS-5.10'},
                      :flavor_id => 'c1.xlarge',
                      :key_name  => 'jenkinskey',
                      :groups    => 'load-test',
                      :user      => 'root'}
  CENTOS6_STACK   = { :image_id  => 'ami-19283b5c', # jenkins-centos-6.6-test-image
                      :tags => {'Name' => 'CentOS-6.6'},
                      :flavor_id => 'c1.xlarge',
                      :key_name  => 'jenkinskey',
                      :groups    => 'load-test',
                      :user      => 'root'}
  STACKS          = [ UBUNTU_STACK, CENTOS5_STACK, CENTOS6_STACK ]
  STACK_SIZE      = STACKS.size
  DEB_DEPS        = [ "build-essential",
                      "zlib1g-dev",
                      "libssl-dev",
                      "libcurl4-openssl-dev",
                      "libreadline5-dev",
                      "libsqlite3-0",
                      "libsqlite3-dev" ]
  RPM_DEPS        = [ "gcc-c++",
                      "zlib-devel",
                      "curl-devel",
                      "pcre-devel",
                      "openssl-devel",
                      "readline-devel" ]
end