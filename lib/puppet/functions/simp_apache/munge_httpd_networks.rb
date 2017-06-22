# Provides a method by which an array of networks can be properly formatted
# for an Apache Allow/Deny segment.
#
# This handles the case of 0.0.0.0/0, which Apache doesn't care for and
# this function will convert to 'ALL'.
#
# The case where a <dotted quad address>/<dotted quatted netmask> is
# passed is also handled since Apache doesn't care for these at all.
Puppet::Functions.create_function(:'simp_apache::munge_httpd_networks') do

  # @param networks Array of networks to be converted to Apache format
  # @return [Array] Array of network s formated appropriately for Apache
  dispatch :munge_httpd_networks do
    required_param 'Array', :networks
  end

  def munge_httpd_networks(networks)
    httpd_networks = []
    networks.flatten.each do |x|
      next if x.nil?

      x.strip!
      next if x.empty?

      #TODO what about IPv6 addresses?
      if x =~ /^0\.0\.0\.0/
        httpd_networks << 'ALL'
      elsif x =~ /\/\d{1,3}\./
        httpd_networks << call_function('nets2cidr', x)
      else
        httpd_networks << x
      end
    end

    httpd_networks.flatten
  end
end
