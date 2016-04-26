require 'redis'
$:.unshift File.join(File.dirname(__FILE__),'..','..','..','lib')
require 'rhoconnect'
include Rhoconnect
  
module Bench
  class MockClient
    include Logging
        
    def initialize(thread_id,iteration,client_id)
      @thread_id,@iteration,@client_id = thread_id,iteration,client_id
    end
    
    def parse(message)
      msg = JSON.parse(message)
      raise Exception.new("#{log_prefix} Wrong message format. Message: #{message.inspect}") if msg.size < 6
      raise Exception.new("#{log_prefix} Wrong protocol version. Message: #{message.inspect}") if msg[0]['version'] != 3
      msg.each do |p|
        insert(p['insert']) if p['insert']
        delete(p['delete']) if p['delete']
      end
    end
    
    def insert(objects)
      Store.put_data(doc_type,objects,true)
    end
    
    def delete(objects)
      Store.delete_data(doc_type,objects)
    end
  
    def verify(objects)
      Store.get_data(doc_type) == objects
    end
      
    def doc_type
      "#{@client_id.to_s}:mock:cd"
    end  

  end
end