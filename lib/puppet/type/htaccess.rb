Puppet::Type.newtype(:htaccess) do
  @doc = "Manages the contents of htaccess files using the htpasswd command.
          Right now the $namevar must be a path/user combination as
          documented under the $name parameter. Hopefully, this can be fixed
          in the future.

          Note: If you want different permissions than root:root 640, you
          will need to create a 'file' object to manage the target file."

  ensurable

  newparam(:name) do
    isnamevar
    desc "A variable of the format 'path:username'. This will hopefully be
          split in the future but, for now, you cannot use usernames that
          contain a colon ':'."

    validate do |value|
      target = value.split(':').first

      fail Puppet::Error, "name is missing either the path or the username. Name format must be 'path:username'" if value !~ /.+:.+/

      fail Puppet::Error, "File paths must be fully qualified, not #{target}" if value !~ /^\//
    end
  end

  newproperty(:password) do
    desc "The user's new password either as an SHA hash or as plain text.
          Anything not prefixed with {SHA} will be treated as plain text."

    def insync?(is)
      is == @should[0]
    end

    def sync
      provider.passwd_sync
    end

    def retrieve
      return provider.passwd_retrieve
    end

    munge do |value|
      unless value =~ /^\{SHA\}/
        require 'digest/sha1'
        require 'base64'
        value = "{SHA}"+Base64.encode64(Digest::SHA1.digest(value)).chomp!
      end

      value
    end
  end

  autorequire(:file) do
    torequire = self[:name].split(':').first

    if catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:file)) and r[:name] == torequire }.empty? then
      err "You must declare a 'file' object to manage #{torequire}!"
    end

    torequire
  end

  validate do
    required_fields = [ :password ]

    required_fields.each do |req|
      unless @parameters.include?(req)
        fail Puppet::Error, "You must specify #{req}."
      end
    end
  end

end
