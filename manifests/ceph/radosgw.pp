#
# Class rjil::ceph::radosgw
# Purpose: Configure ceph radosgw
#
# == Parameters
#

class rjil::ceph::radosgw (
  $ssl_secrets_package_name         = 'jiocloud-ssl-certificate',
  $jiocloud_ssl_cert_package_ensure = 'present',
  $ssl                              = false,
  $port                             = 80,
) {

  include ::ceph::conf
  include ::ceph::radosgw
  include ::rsyslog::client

  ensure_packages($ssl_secrets_package_name, {ensure => $jiocloud_ssl_cert_package_ensure})

  ##
  # Validation tests
  ##
  class {'rjil::test::ceph_radosgw':
    ssl  => $ssl,
    port => $port,
  }

  rjil::test::check { 'radosgw':
    address => '127.0.0.1',
    port    => $port,
    ssl     => $ssl,
  }

  rjil::jiocloud::consul::service { 'radosgw':
    tags          => ['real'],
    port          => $port,
  }

}
