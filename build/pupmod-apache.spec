Summary: Apache Puppet Module
Name: pupmod-apache
Version: 4.1.0
Release: 16
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-auditd >= 4.1.0-2
Requires: pupmod-common >= 4.1.0-5
Requires: pupmod-concat >= 4.0.0-0
Requires: pupmod-iptables >= 4.1.0-3
Requires: pupmod-logrotate >= 4.1.0-0
Requires: pupmod-pki >= 3.0.0-0
Requires: pupmod-rsync >= 4.0.0-14
Requires: pupmod-rsyslog >= 4.1.0-0
Requires: puppet >= 3.3.0
Requires: puppetlabs-stdlib >= 4.1.0-0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-apache-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure Apache and component
sites.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/apache

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/apache
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/apache

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/apache

%files
%defattr(0640,root,puppet,0750)
%{prefix}/apache

%post
#!/bin/sh

if [ -d %{prefix}/apache/plugins ]; then
  /bin/mv %{prefix}/apache/plugins %{prefix}/apache/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-16
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-15
- Changed puppet-server requirement to puppet

* Mon Dec 15 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-14
- Updated the templates to use mod_version instead of custom apache_version fact.
- Ensure that mod_ldap in installed by default on TC versions > 5.0.
- Properly scoped all custom function definitions.

* Thu Dec 04 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-13
- Updated to properly handle the SSL protocols in Apache. We now add a
  + if one is warranted and just keep the entry if it starts with a +
  a minus or is 'all'.

* Fri Oct 17 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-12
- CVE-2014-3566: Updated protocols to mitigate POODLE.

* Mon Sep 08 2014 Trevor Vaughan <tvaughan@onyxpoint.com> 4.1.0-11
- Properly confined the apache_version fact.
- Updated the apache::validate hash to not include booleans. They are
  not allowed on the left hand side of the comparison hash.

* Tue Aug 26 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-10
- Fixed the apache_version fact to return unkown when Apache is not installed.

* Tue Jul 29 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-9
- Fix munge_httpd_networks
- Updated to use /var/www for SIMP>=5

* Mon Jul 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-9
- Updated munge_httpd_networks to strip out entries that are blank or
  nil.

* Mon Jun 23 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-8
- Fixed SELinux check for when selinux_current_mode is not found.
- RHEL7 compatiblity updates
- Added a fact, 'apache_version', to allow for minute differences
  between the 2.2 and 2.4 versions of Apache

* Sun Jun 22 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-8
- Removed MD5 file checksums for FIPS compliance.

* Fri Jun 13 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-7
- Unbound apache package from service to fix ordering in bootstrap

* Fri May 16 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-6
- Updated cipher set in SSL to be an array instead of a string.

* Wed Apr 30 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-5
- Removed all references to $::primary_ipaddress and replaced them with a
  collection of all local IP addresses in the ERB files.

* Tue Apr 29 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-5
- Updated apache_limits required directives from core to mod_authnz_ldap,
  by changing Require user/group "foo" to Require ldap-user/group foo.

* Mon Apr 14 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Removed the ks and yum sites and moved them into the simp module.
- Removed the runpuppet templated and moved it into the simp module.

* Fri Apr 04 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-4
- Selinux booleans now set if mode != disabled

* Wed Mar 19 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Removed the apache_syslog script and replaced all calls with calls
  to logger for scalability.
- Updated the munge_httpd_networks function to call nets2cidr where appropriate
  and accept pretty much everything else since Apache can take so many
  different options.
- Removed the broken PKI copy code and call the new pki::copy define.

* Fri Mar 14 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Re-added the ability to have Apache log via syslog directly.
- Removed the passgen template and replaced it with a call to the
  passgen function.

* Wed Feb 12 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Ensure that apache::conf::allowroot defaults to ['127.0.0.1','::1']
- Small amounts of cleanup to start complying with the PL coding standards.
- Added management of the $data_dir (/srv/www) to the ::apache class.
  This removes it from floating in the manifests space.
- Modified the apache restart script to do a reload and then restart
  if that fails. This should ensure minimal downtime of all running
  apps.
- Updated the runpuppet script to ensure that the clients will
  properly use the new variables and that servers can kick other
  servers.
- Update to runpuppet to ensure that the first run of puppet has a waitforcert
  to allow for manual certificate signing.  Submission from Lab76.org.

* Thu Jan 09 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Updated the runpuppet init script such that it will remain on the
  system but in a completely disabled state.

* Tue Nov 12 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Restructured the entire apache module to be hiera friendly.
- Eliminated all singleton defines.
- Added the ability to use a custom PKI source and not use the SIMP
  source.
- Added toggles for all SIMP specific items.

* Thu Oct 03 2013 Kendall Moore <kmoore@keywcorp.com> - 4.0.0-14
- Updated all erb templates to properly scope variables.

* Wed Oct 02 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-14
- Use versioncmp for all version comparisons.

* Wed Sep 11 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0-13
- Added an apache::validate class that currently supports the apache_auth
  material but could be used to hold other values.
- Added an apache_limits function which takes a hash of options and returns a
  formatted set of 'Limit' statements suitable for direct insertion into an
  Apache configuration.
- Added an apache_auth function which takes a hash of options and returns a
  formatted segment of Apache auth sections. Currently supports 'file'
  (htpasswd) and 'ldap'.

* Thu May 02 2013 Trevor Vaughan <tvaughan@onyxpoint.com>
4.0-12
- Work performed jointly with Kendall Moore <kmoore@keywcorp.com>
- Named properly switches between chroot and non-chroot versions based on
  whether or not SELinux is enforcing.

* Mon Feb 25 2013 Maintenance
4.0-12
- Added a call to $::rsync_timeout to the rsync call since it is now required.

* Wed Feb 20 2013 Maintenance
4.0-11
- Updated the ssl.conf and httpd.conf templates because function calls require
  an argument of an array rather than allowing for single string arguments.

* Fri Jan 04 2013 Maintenance
4.0-10
- Added a custom function 'munge_httpd_networks' that will accept an array, or
  string, and return an array of translated network addresses. At this time,
  the only translation is from 0.0.0.0* to 'ALL' since apache really doesn't
  like 0.0.0.0/0.

* Mon Oct 22 2012 Maintenance
4.0-9
- Updated the runpuppet script to not log remotely during the puppet
  runs so that large numbers of spawning client won't kill the master.

* Wed Oct 03 2012 Maintenance
4.0.0-8
- Added a sleep statement after the reboot in the runpuppet script to
  keep it other startup scripts from continuing.

* Thu Jul 05 2012 Maintenance
4.0.0-7
- Cleaned up the yum and ks templates.
- Added the Option +Indexes to the yum and ks configurations. This allows for
  browsing of the yum repositories which is important for virt-manager and
  other kickstart utilities.

* Thu Jun 07 2012 Maintenance
4.0.0-6
- Ensure that Arrays in templates are flattened.
- Call facts as instance variables.
- Moved mit-tests to /usr/share/simp...
- Updated to work with IPv6 addresses.
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
4.0.0-5
- Improved test stubs.

* Mon Feb 13 2012 Maintenance
4.0-4
- Added the ability for the apache user to be in multiple groups.

* Fri Dec 23 2011 Maintenance
4.0-3
- Added an initial set of tests.
- Scoped all of the top level variables.
- Modified the runpuppet template so that it properly detects the system's
  status as a master.
- Replaced instances of 'ipaddress' with 'primary_ipaddress'

* Sat Nov 19 2011 Maintenance
4.0-2
- Moved the 'domain' entries after the ip addresses so that DNS lookups would
  happen last.

* Fri Aug 12 2011 Maintenance
4.0-1
- Added support for a variable 'ks_ntp_servers' which will override the
  'ntp_servers' variable from vars.pp inside of runpuppet.erb.
- Ensure that the '-b' option is passed to ntpdate in runpuppet.erb.

* Tue Jul 12 2011 Maintenance
4.0-0
- Added a variable $runpuppet_print_stats to runpuppet.erb that will enable
  --evaltrace and --summarize if set to 'true'.
- Updated the htaccess type to properly work with Puppet >= 2.6
- Made some RHEL6 specific compatibilty changes.
- Added additional tags to the puppet runs in runpuppet.

* Mon Apr 18 2011 Maintenance - 2.0.0-3
- Changed puppet://$puppet_server/ to puppet:///
- The dhcp module now expects to have an associated rsync space that is
  password protected.
- Added comments to apache::ssl::setup to note that users will need to manage
  their own service restarts if they use alternate certificates.
- Ensure that apache restarts if any part of the certificte space is changed.
- Additional options have been added to the SSL configuration for flexibility.
- Removed Ganglia related material.
- Remove welcome.conf on the systems.
- Updated to use syslog by default.

* Fri Feb 04 2011 Maintenance - 2.0.0-2
- Changed all instances of defined(Class['foo']) to defined('foo') per the
  directions from the Puppet mailing list.
- Bug fix in the puppet_passenger template to ensure that PassengerMaxPoolSize
  is not set to 0 and also accounts for other units coming back from Facter.
- Converted to using rsync native type

2.0.0-1
- Added 'Allow from' to ganglia site template.
- Updated default values for number of passenger instances
- Updated default values for MaxClients and ServerLimit
- Updated runpuppet to use --no-splay
- Updated default value of purge in httpd_conf to false

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Fri Jan 7 2011 Maintenance - 1.0-6
- Now ensure that the apache rsync does *not* delete the underlying files. This
  turned out to be a poor initial design decision.
- Fixed bug that causes the apache rsync space to never be retrieved.
- Updated passenger template to use correct rubylib path
- Added a httpd_conf $purge variable that translates into whether or not to
  remove anything that we don't have in rsync.

* Wed Jan 5 2011 Maintenance - 2.0.0
- Updated for the simp 2.0.0-alpha release
- Fixed bug causing apache rsync space to never be retrieved.

* Mon Dec 6 2010 Maintenance - 1.0-5
- Added the ability to modify the main user/group that apache runs as.
  The group of all component files is still set to 'apache' so you'll need to
  take that into account when you configure your site files.
- Added Ganglia Site

* Thu Oct 28 2010 Maintenance - 1.0-4
- Modified puppet_mongrel template to use revocation file.

* Tue Oct 26 2010 Maintenance - 1.0-3
- Converting all spec files to check for directories prior to copy.

* Thu Aug 12 2010 Maintenance
1.0-2
- runpuppet.erb now redirects all output to the log file and runs in verbose mode.

* Wed Jul 21 2010 Maintenance
1.0-1
- More refactoring.

* Wed Jun 02 2010 Maintenance
1.0-0
- CRLs now work properly.
- Passenger listens on 8140 and 8141 by default.
- Improved puppet_passenger template.
- Now point the certs in the mongrel and passenger templates at the local CA
  certs, not the CA server certs.
- Code refactor.

* Thu Apr 29 2010 Maintenance
0.1-24
- Changed operatingsystemrelease to lsbmajdistrelease since RHEL5.5 shows as 5.5 and not 5.

* Wed Mar 17 2010 Maintenance
0.1-23
- Added a small sleep to the apache restart that prevents a race condition
  caused by calling 'service httpd restart' just after 'service httpd stop'

* Thu Jan 28 2010 Maintenance
0.1-22
- Fixed a bug with the format of the puppet command variable in runpuppet.
- The script now executes cleanly out of the box.

* Thu Jan 14 2010 Maintenance
0.1-21
- Added 'TraceEnable off' to the default httpd.conf.

* Tue Dec 15 2009 Maintenance
0.1-20
- Add a yum clean all prior to running the puppetd run in runpuppet.

* Thu Nov 05 2009 Maintenance
0.1-19
- Prevent the runpuppet script from printing diff information to the logs.
