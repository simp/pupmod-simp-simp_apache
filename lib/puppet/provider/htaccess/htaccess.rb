Puppet::Type.type(:htaccess).provide :htaccess do
  require 'fileutils'

  desc "Htaccess provider"

  HTACCESS_EDIT_MSG = "# This file managed by Puppet. Please do not edit by hand!"

  def create_target
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    FileUtils.touch(target)
    FileUtils.chmod(0640,target)
    FileUtils.chown('root','root',target)
  end

  def target_exist?
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    File.exist?(target)
  end

  def mod_target(mod_type)
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      self.target_exist? or self.create_target

      tmpname = "#{File.dirname(target)}/.#{File.basename(target)}.htpasswd.tmp"
      outfile = File.open(tmpname,'w+')
      FileUtils.chmod(0600,tmpname)

      fh = File.open(target,'r')

      # Check for the edit message and add if necessary.
      if fh.eof?
        outfile.puts(HTACCESS_EDIT_MSG)
      elsif not fh.readline.chomp.eql?(HTACCESS_EDIT_MSG)
        outfile.puts(HTACCESS_EDIT_MSG)
        fh.rewind
      else
        fh.rewind
      end

      if mod_type.eql?("create")

        fh.each do |line|
          line.chomp!
          outfile.puts(line)
        end
        outfile.puts("#{username}:#{@resource[:password]}")

      elsif mod_type.eql?("modify")

        fh.rewind
        fh.each do |line|
          line.chomp!
          (l_uname,l_pass) = line.split(':')

          if l_uname.eql?(username) then
            outfile.puts("#{username}:#{@resource[:password]}")
          else
            outfile.puts(line)
          end
        end

      elsif mod_type.eql?("delete")
        fh.rewind
        fh.each do |line|
          line.chomp!
          if not line.split(':').first.eql?(username) then
            outfile.puts(line)
          end
        end
      end

      fh.close
      outfile.close
      FileUtils.cp(tmpname,target)
      FileUtils.rm(tmpname)
    rescue Exception => e
      fail Puppet::Error, e
    end

  end

  def create
    mod_target("create")
  end

  def destroy
    mod_target("delete")
  end

  def passwd_sync
    mod_target("modify")
    return nil
  end

  def exists?
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      File.open(target,'r').each do |line|

        line.chomp!

        if line.split(':').first.eql?(username) then
          return true
        end
      end

      return false
    rescue Exception => e
      fail Puppet::Error, e
    end
  end

  def passwd_retrieve
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      self.target_exist? or return nil

      File.open(target,'r').each do |line|
        line.chomp!
        (l_uname,l_pass) = line.split(':')

        if l_uname.eql?(username) then
          return l_pass
        end
      end

    rescue Exception => e
      fail Puppet::Error, e
    end

    return nil
  end

end
