class SampleAdapter < SourceAdapter
  def initialize(source)
    super(source)
  end

  # to test custom partitions
  def self.partition_name(user_id)
    user_id[0..2] == 'cus' ? 'custom_partition' : user_id
  end
 
  def login
    raise SourceAdapterLoginException.new('Error logging in') if _is_empty?(current_user.login)
    true
  end
 
  def query(params=nil)
    _read('query',params)
  end
  
  def search(params=nil)
    _read('search',params)
  end
 
  def sync
    super
  end
  
  def validate(operation,operation_data,client_ids)
    invalid_meta = {}
    used_ids = {}
    operation_data.each_with_index do |client_operation_data,index|
      client_id = client_ids[index]
      client_operation_data.each do |source_operation_entry|
        source_id = source_operation_entry[0]
        list_of_objs = source_operation_entry[1]
        list_of_objs.each_with_index do |obj_entry, objindex|
          key = obj_entry[0]
          objvalue = obj_entry[1]
          if objvalue['force_duplicate_error'] == '1'
            invalid_meta[index] ||= {}
            invalid_meta[index][source_id] ||= {}
            invalid_meta[index][source_id][objindex] ||= {}
            invalid_meta[index][source_id][objindex][:error] = "Error during #{operation}: object conflict detected"
          end
          if objvalue['duplicate_of_cid']
            invalid_meta[index] ||= {}
            invalid_meta[index][source_id] ||= {}
            invalid_meta[index][source_id][objindex] ||= {}
            invalid_meta[index][source_id][objindex][:duplicate_of] = true
            master_client_id = objvalue['duplicate_of_cid']
            master_objindex = objvalue['duplicate_of_entry_index'].to_i
            master_index = objvalue['duplicate_of_queue_index'].to_i
          
            invalid_meta[master_index] ||= {}
            invalid_meta[master_index][source_id] ||= {}
            invalid_meta[master_index][source_id][master_objindex] ||= {}
            invalid_meta[master_index][source_id][master_objindex][:duplicates] ||= []
            invalid_meta[master_index][source_id][master_objindex][:duplicates] <<  {:client_id => client_id, :key => key, :value => objvalue}
          end
        end
      end
    end
    invalid_meta
  end
 
  def create(create_hash)
    Store.put_data('test_create_storage',{create_hash['_id']=>create_hash},true)
    raise SourceAdapterException.new("ID provided in create_hash") if create_hash['id']
    _raise_exception(create_hash) 
    'backend_id' if create_hash and create_hash['link']
  end
 
  def update(update_hash)
    raise SourceAdapterException.new("No id provided in update_hash") unless update_hash['id']
    Store.put_data('test_update_storage',{update_hash['id']=>update_hash},true)
    _raise_exception(update_hash) 
  end
 
  def delete(delete_hash)
    raise SourceAdapterException.new("No id provided in delete_hash") unless delete_hash['id']
    raise SourceAdapterServerErrorException.new("Error delete record") if delete_hash['id'] == ERROR
    Store.put_data('test_delete_storage',{delete_hash['id']=>delete_hash},true)
  end

  # This is not correect (tempfile should not be used)
  # but - for specs - it is sufficient
  def store_blob(obj,field_name,blob)
    blob[:tempfile].path if blob[:tempfile]
  end
 
  def logoff
    @result = Store.get_data('test_db_storage')
    raise SourceAdapterLogoffException.new(@result[ERROR]['an_attribute']) if @result[ERROR] and 
      @result[ERROR]['name'] == 'logoff error'
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
  
  def _raise_exception(data_hash)
    if data_hash and data_hash['name'] == 'wrongname' or data_hash['id'] == 'error'
      raise SourceAdapterServerErrorException.new(data_hash['an_attribute']) 
    end
  end
  
  def _read(operation,params)
    @result = Store.get_data('test_db_storage')
    if params and params['stash_result']
      stash_result
      # @result is nil at this point; if @result is empty then md will be cleared
    else   
      raise SourceAdapterServerErrorException.new(@result[ERROR]['an_attribute']) if @result[ERROR] and 
        @result[ERROR]['name'] == "#{operation} error"
      @result.reject! {|key,value| value['name'] != params['name']} if params
    end  
    @result
  end
end