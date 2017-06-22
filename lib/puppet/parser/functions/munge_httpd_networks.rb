module Puppet::Parser::Functions

  newfunction(:munge_httpd_networks, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
      Provides a method by which an array of networks can be properly formatted
      for an Apache Allow/Deny segment.

      This handles the case of 0.0.0.0/0, which Apache doesn't care for and
      this function will convert to 'ALL'.

      The case where a DDQ address is passed is also handled since Apache
      doesn't care for these at all.

    ENDHEREDOC

    function_deprecation([:munge_httpd_networks, 'This method is deprecated, please use simp_apache::munge_httpd_networks'])

    Puppet::Parser::Functions.autoloader.load(
      File.expand_path(File.dirname(__FILE__) + '/../../../../../simplib/lib/puppet/parser/nets2cidr.rb')
    )
    unless args.length > 0 then
      raise Puppet::ParseError, ("munge_httpd_networks(): wrong number of arguments (#{args.length}; must be > 0)")
    end

    httpd_networks = []
    Array(args).flatten.each do |x|
      next if x.nil?

      x.strip!
      next if x.empty?

      if x =~ /^0\.0\.0\.0/ then
        httpd_networks << 'ALL'
      elsif x =~ /\/\d{1,3}\./
        httpd_networks << function_nets2cidr(x)
      else
        httpd_networks << x
      end
    end

    httpd_networks.flatten
  end
end
