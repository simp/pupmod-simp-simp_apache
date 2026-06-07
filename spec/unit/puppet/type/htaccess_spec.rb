require 'spec_helper'

describe Puppet::Type.type(:htaccess) do
  let(:htaccess_type) { described_class }

  it 'requires <fully-qualified path>:<username> for the name param' do
    expect {
      htaccess_type.new(
        name: '/fully/qualified/path:username',
        password: 'badpassword',
      )
    }.not_to raise_error

    expect {
      htaccess_type.new(
        name: 'onefield',
        password: 'badpassword',
      )
    }.to raise_error(%r{name is missing either the path or the username. Name format must be 'path:username'})

    expect {
      htaccess_type.new(
        name: ':empty_first_field',
        password: 'badpassword',
      )
    }.to raise_error(%r{name is missing either the path or the username. Name format must be 'path:username'})

    expect {
      htaccess_type.new(
        name: 'empty_second_field:',
        password: 'badpassword',
      )
    }.to raise_error(%r{name is missing either the path or the username. Name format must be 'path:username'})

    expect {
      htaccess_type.new(
        name: 'not/fully/qualified/path:username',
        password: 'badpassword',
      )
    }.to raise_error(%r{File paths must be fully qualified, not not/fully/qualified/path})
  end

  it 'requires the password param' do
    expect { htaccess_type.new(name: '/fully/qualified/path:username') }.to raise_error(%r{You must specify password.})
  end
end
