class MockAdapter < Rhoconnect::Model::Base
  def initialize(source) 
    super(source)
  end
 
  def login
    true
  end

 def query(params=nil)
   Store.lock(lock_name,1) do
     @result = Store.get_data(db_name)
   end
   @result
 end
 
 def create(create_hash)
   id = create_hash['mock_id']
   Store.lock(lock_name,1) do
     Store.put_data(db_name,{id=>create_hash},true) if id
   end
   id
 end

 def update(update_hash)
   id = update_hash.delete('id')
   return unless id
   Store.lock(lock_name,1) do
     data = Store.get_data(db_name)
     return unless data and data[id]
     update_hash.each do |attrib,value|
       data[id][attrib] = value
     end
     Store.put_data(db_name,data)
   end
 end

 def delete(delete_hash)
   id = delete_hash.delete('id')
   Store.lock(lock_name,1) do
     Store.delete_data(db_name,{id=>delete_hash}) if id
   end
 end

 def db_name
   "test_db_storage:#{@source.app_id}:#{@source.user_id}"
 end
 
 def lock_name
   "lock:#{db_name}"
 end
 
 private
 
end