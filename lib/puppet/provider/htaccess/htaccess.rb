Puppet::Type.type(:htaccess).provide :htaccess do
  require 'fileutils'

  desc 'Htaccess provider'

  HTACCESS_EDIT_MSG = '# This file managed by Puppet. Please do not edit by hand!'.freeze

  def create_target
    target = @resource[:name].split(':').first
    @resource[:name].split(':').last

    FileUtils.touch(target)
    FileUtils.chmod(0o640, target)
    FileUtils.chown('root', 'root', target)
  end

  def target_exist?
    target = @resource[:name].split(':').first
    @resource[:name].split(':').last

    File.exist?(target)
  end

  def mod_target(mod_type)
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      target_exist? or create_target

      tmpname = "#{File.dirname(target)}/.#{File.basename(target)}.htpasswd.tmp"
      outfile = File.open(tmpname, 'w+')
      FileUtils.chmod(0o600, tmpname)

      fh = File.open(target, 'r')

      # Check for the edit message and add if necessary.
      if fh.eof?
        outfile.puts(HTACCESS_EDIT_MSG)
      elsif !fh.readline.chomp.eql?(HTACCESS_EDIT_MSG)
        outfile.puts(HTACCESS_EDIT_MSG)
        fh.rewind
      else
        fh.rewind
      end

      if mod_type.eql?('create')

        fh.each do |line|
          line.chomp!
          outfile.puts(line)
        end
        outfile.puts("#{username}:#{@resource[:password]}")

      elsif mod_type.eql?('modify')

        fh.rewind
        fh.each do |line|
          line.chomp!
          (l_uname,) = line.split(':')

          if l_uname.eql?(username)
            outfile.puts("#{username}:#{@resource[:password]}")
          else
            outfile.puts(line)
          end
        end

      elsif mod_type.eql?('delete')
        fh.rewind
        fh.each do |line|
          line.chomp!
          unless line.split(':').first.eql?(username)
            outfile.puts(line)
          end
        end
      end

      fh.close
      outfile.close
      FileUtils.cp(tmpname, target)
      FileUtils.rm(tmpname)
    rescue => e
      raise Puppet::Error, e.message
    end
  end

  def create
    mod_target('create')
  end

  def destroy
    mod_target('delete')
  end

  def passwd_sync
    mod_target('modify')
    nil
  end

  def exists?
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      File.open(target, 'r').each do |line|
        line.chomp!

        if line.split(':').first.eql?(username)
          return true
        end
      end

      false
    rescue => e
      raise Puppet::Error, e.message
    end
  end

  def passwd_retrieve
    target = @resource[:name].split(':').first
    username = @resource[:name].split(':').last

    begin
      target_exist? or return nil

      File.open(target, 'r').each do |line|
        line.chomp!
        (l_uname, l_pass) = line.split(':')

        if l_uname.eql?(username)
          return l_pass
        end
      end
    rescue => e
      raise Puppet::Error, e.message
    end

    nil
  end
end
