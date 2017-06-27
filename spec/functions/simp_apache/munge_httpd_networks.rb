require 'spec_helper'

describe 'simp_apache::munge_httpd_networks' do

  context 'with valid input' do
    it 'transforms IPv4 networks to apache settings format' do
      input = ['0.0.0.0', '0.0.0.0/0', ' 1.2.3.4 ', '1.2.3.0/24', '1.2.0.0/255.255.0.0']
      expected_output = ['ALL', 'ALL', '1.2.3.4', '1.2.3.0/24', '1.2.0.0/16']
      is_expected.to run.with_params(input).and_return(expected_output)
    end

    it 'passes through hostnames to apache settings format' do
      input = ['host1', 'host2']
      is_expected.to run.with_params(input).and_return(input)
    end

    pending 'transforms IPV6 networks to apache settings format'
  end

  context 'with invalid input' do
    # FIXME simplib net2cidr needs to be fixed
    pending 'fails when transformation of an invalid IPv4 network is requested'  do
      input = ['1.2.3.4/34', '1.2.3..']
      is_expected.to run.with_params(input).and_raise_error(/is not a valid IP address/)
    end

    it 'fails when transformation of an invalid IPv4 network is requested'  do
      input = ['1.2.3.4/255.']
      is_expected.to run.with_params(input).and_raise_error(/is not a valid IP address/)
    end

    pending 'fails when transformation of an invalid IPV6 network is requested' 
  end
end
