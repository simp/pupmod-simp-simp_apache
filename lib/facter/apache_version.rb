#
# Return the version of apache installed on the system.
#
# Returns 'unknown' if the version cannot be determined.
#
Facter.add('apache_version') do
  apachectl = Facter::Core::Execution.which('apachectl')
  confine { apachectl }

  setcode do
    apache_version = 'unknown'
    begin
      `#{apachectl} -v`.to_s.split("\n").first =~ %r{((\d\.?)+)}
      apache_version = Regexp.last_match(1) unless Regexp.last_match(1).to_s.empty?
    rescue Errno::ENOENT
      # No-op because we only care that the version is unknown if we can't execute a version check.
    end
    apache_version
  end
end
