require 'rubygems'
require 'rspec'
require 'excon'
$:.unshift File.join(File.dirname(__FILE__),'..')
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bench/logging'
require 'bench/mock_client'
require 'bench/utils'
require 'bench/result'
require File.join(File.dirname(__FILE__), '..', '..', 'spec', 'spec_helper')

include Bench

def set_state(state)
  state.each do |dockey,data|
    if data.is_a?(Hash) or data.is_a?(Array)
      Store.put_data(dockey,data)
    else
      Store.put_value(dockey,data)
    end
  end
end

def verify_result(result)
  result.each do |dockey,expected|
    if expected.is_a?(Hash)
      Store.get_data(dockey).should == expected
    elsif expected.is_a?(Array)
      Store.get_data(dockey,Array).should == expected
    else
      Store.get_value(dockey).should == expected
    end
  end
end
