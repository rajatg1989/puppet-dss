## Class: rjil::system
## Purpose: to group all system level configuration together.

class rjil::system(
  $proxies                       = {},
  $dhclient_override_domain_name = undef,
  $puppet_report_keep_hours      = 24,
) {

  ##
  ## It is decided to keep all devices in UTC timezone
  ## This will keep all our systems in single timezone even if we have servers
  ## outside
  ##    and in case we might have to get any external providers' services
  ##

  include ::timezone

  include rjil::system::apt
  include rjil::system::accounts
  include rjil::system::metrics

  ensure_packages(['molly-guard','tmpreaper'])

  ##
  # delete puppet reports which are older than $puppet_report_keep_hours hours
  # Ideally it should have added in tmpreaper daily cron script, but with the
  # current tmpreaper daily cron script, it is not possible to provide different
  # timespecs for different directories.
  # Create a cron to run tmpreaper once every day
  ##
  cron {'purge_puppet_reports':
    command => "tmpreaper -a  ${puppet_report_keep_hours}h /var/lib/puppet/reports/${::fqdn}",
    user    => root,
    hour    => 2,
    minute  => 0
  }

  ##
  # override domain name in dhclient
  ##
  if $dhclient_override_domain_name {
    file_line {$dhclient_override_domain_name:
      path => '/etc/dhcp/dhclient.conf',
      line => "supersede domain-name \"${dhclient_override_domain_name}\";",
      match => '^supersede\s+domain-name.*',
    }
  }

  ## Setup tests
  rjil::test {'check_timezone.sh':}

  Anchor['rjil::system::start'] -> Class['::timezone'] -> Anchor['rjil::system::end']
  #contain rjil::system::ntp #hardware team maintaining it 

  ## apt and accounts have circular dependancy, so making both of them dependant to anchors
  anchor { 'rjil::system::start':
    before => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }
  anchor { 'rjil::system::end':
    require => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }

  ##
  ## Added security banner messages
  ##

  $issue = [ '/etc/issue.net','/etc/issue' ]

  file { $issue:
    ensure        => file,
    owner         => root,
    group         => root,
    mode          => '0644',
    source        => "puppet:///modules/${module_name}/_etc_issue",
  }

  create_resources(rjil::system::proxy, $proxies)

  ##
  # Add domain search in resolvconf.
  # This is required to get matchmaker working - matchmaker ring driver need the
  # hostname without domain name to be resolved.
  ##

  file_line {'domain_search':
    path  => '/etc/resolvconf/resolv.conf.d/base',
    line  => 'search node.consul service.consul',
    match => 'search .*'
  }

  exec {'resolvconf':
    command     => 'resolvconf -u',
    refreshonly => true,
    subscribe   => File_line['domain_search'],
  }

  ##
  # autocompletion of hostnames for ssh and host commands.
  # TODO: this will remove the autocompletion for commandline options, which
  # need to be fixed.
  ##
  file { '/etc/bash_completion.d/host_complete':
    ensure        => file,
    owner         => root,
    group         => root,
    mode          => '0644',
    source        => "puppet:///modules/${module_name}/bash_completion.d_host_complete"
  }

  file { '/etc/securetty':
    mode => '0600'
  }

  sysctl::value {
    'net.ipv4.conf.all.accept_redirects':        value => 0;
    'net.ipv4.conf.default.accept_redirects':    value => 0;
    'net.ipv4.conf.all.secure_redirects':        value => 0;
    'net.ipv4.conf.default.secure_redirects':    value => 0;
    'net.ipv4.conf.default.accept_source_route': value => 0;
    'net.ipv4.conf.all.send_redirects':          value => 0;
    'net.ipv4.conf.default.send_redirects':      value => 0;
    'net.core.rmem_max':		        value => 56623104;
    'net.core.wmem_max':			value => 56623104;
    'net.core.rmem_default':		        value => 56623104;
    'net.core.wmem_default':			value => 56623104;
    'net.core.optmem_max':			value => 40960;
    'net.ipv4.tcp_rmem':		        value => "4096\t87380\t56623104";
    'net.ipv4.tcp_wmem':		        value => "4096\t65536\t56623104";
    'net.core.somaxconn':			value => 1024;
    'net.core.netdev_max_backlog':		value => 50000;
    'net.ipv4.tcp_max_syn_backlog':		value => 4096;
    'net.ipv4.tcp_max_tw_buckets':		value => 2000000;
    'net.ipv4.tcp_tw_recycle':			value => 1;
    'net.ipv4.tcp_tw_reuse':			value => 1;
    'net.ipv4.tcp_fin_timeout':		        value => 10;
    'net.ipv4.tcp_slow_start_after_idle':	value => 0;
    'net.ipv4.udp_rmem_min':			value => 8192;
    'net.ipv4.udp_wmem_min':			value => 8192;
    'kernel.pid_max':				value => 4194303;
  }
}	
