require 'json'
require 'rest_client'
require 'uri'

module Rhoconnect
  # register the adapter as pre-defined
  Rhoconnect.register_predefined_source('RhoInternalBenchmarkAdapter')
  
  class RhoInternalBenchmarkAdapter < Rhoconnect::Model::Base
     def initialize(source) 
       super(source)
     end

     def login
       true
     end

    def query(params=nil)
      if @source.simulate_time > 0
        #for i in 1..10
        #  RestClient.get('www.google.com')
        #end
        sleep @source.simulate_time
      end
      #Rhoconnect::Store.lock(lock_name,1) do
        @result = Rhoconnect::Store.get_data(db_name)
      #end
      #@result
    end

    def create(create_hash)
      id = create_hash['mock_id']
      Rhoconnect::Store.lock(lock_name,1) do
        Rhoconnect::Store.put_data(db_name,{id=>create_hash},true) if id
      end
      id
    end

    def update(update_hash)
      id = update_hash.delete('id')
      return unless id
      Rhoconnect::Store.lock(lock_name,1) do
        data = Rhoconnect::Store.get_data(db_name)
        return unless data and data[id]
        update_hash.each do |attrib,value|
          data[id][attrib] = value
        end
        Rhoconnect::Store.put_data(db_name,data)
      end
    end

    def delete(delete_hash)
      id = delete_hash.delete('id')
      Rhoconnect::Store.lock(lock_name,1) do
        Rhoconnect::Store.delete_data(db_name,{id=>delete_hash}) if id
      end
      id
    end

    def db_name
      res = ''
      if @source.user_id[0..1] == 'nq'
        res = "test_db_storage:#{@source.app_id}:nquser"
      elsif @source.user_id[0..1] == 'mq'
        res = "test_db_storage:#{@source.app_id}:mquser"
      else
        res = "test_db_storage:#{@source.app_id}:benchuser"
      end
      res
    end

    def lock_name
      "lock:#{db_name}"
    end
  end
end