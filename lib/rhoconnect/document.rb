module Document
  class << self
    def included(base)
      base.extend ClassMethods
    end
  end

  module ClassMethods
    def define_valid_doctypes(doctypes = [])
      @valid_doctypes ||= {}
      doctypes.each do |doctype|
        @valid_doctypes[doctype.to_sym] = :document
      end
      @enforce_valid_doctypes ||= true
    end

    def define_valid_queues(queues = [])
      @valid_doctypes ||= {}
      queues.each do |doctype|
        @valid_doctypes[doctype.to_sym] = :queue
      end
      @enforce_valid_doctypes ||= true
    end

    def valid_doctypes
      @valid_doctypes ||= {}
      @valid_doctypes
    end

    def enforce_valid_doctypes
      @enforce_valid_doctypes ||= false
    end
    def enforce_valid_doctypes=(enforce_flag)
      @enforce_valid_doctypes = enforce_flag
    end
  end

  def set_db_doc(doctype, data, append=false)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).set_db_doc(docname(doctype), data, append)
  end

  def get_db_doc(doctype)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_db_doc(docname(doctype))
  end

  # Store wrapper methods for document
  def get_data(doctype,type=Hash)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_data(docname(doctype), type)
  end

  def get_object(doctype, key)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_object(docname(doctype), key)
  end

  def get_objects(doctype, keys)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_objects(docname(doctype), keys)
  end

  def get_list(doctype)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_list(docname(doctype))
  end

  def get_value(doctype)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).get_value(docname(doctype))
  end

  def put_object(doctype, key, data={})
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).put_object(docname(doctype), key, data)
  end

  def put_data(doctype,data,append=false)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).put_data(docname(doctype),data,append)
  end

  def put_tmp_data(doctype, data, append=false)
    Store.get_store(store_index(doctype)).put_tmp_data(docname(doctype),data,append)  
  end

  def put_list(doctype,data,append=false)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).put_list(docname(doctype),data,append)
  end

  def update_objects(doctype,updates)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).update_objects(docname(doctype),updates)
  end

  def remove_objects(doctype,deletes)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).delete_objects(docname(doctype),deletes)
  end

  def put_value(doctype,data)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).put_value(docname(doctype),data)
  end

  def delete_data(doctype,data)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).delete_data(docname(doctype),data)
  end

  def flush_data(doctype)
    verify_doctype(doctype)
    Store.flush_data(docname(doctype))
  end

  def rename(srcdoctype,dstdoctype)
    verify_doctype(srcdoctype)
    verify_doctype(dstdoctype)
    Store.get_store(store_index(srcdoctype)).rename(docname(srcdoctype),docname(dstdoctype))
  end

  def rename_tmp_data(srcdoctype,dstdoctype)
    verify_doctype(dstdoctype)
    Store.get_store(store_index(srcdoctype)).rename_tmp_data(docname(srcdoctype),docname(dstdoctype))
  end

  def clone(srcdoctype, dstdocname)
    verify_doctype(srcdoctype)
    Store.get_store(store_index(srcdoctype)).clone(docname(srcdoctype), dstdocname)
  end

  # Generate the fully-qualified docname
  def docname(doctype)
    "#{self.class.class_prefix(self.class)}:#{self.app_id}:#{self.doc_suffix(doctype)}"
  end

  # default data sharding
  def store_index(doctype)
    0
  end

  def compute_store_index(doctype, source, user_id)
    index = 0
    # app-partitioned sources go to 0
    # everything else if sharded
    if(source.partition == :user)
      index_char = Digest::SHA1.hexdigest("#{source.partition_name}:#{source.name}")[0]
      # designate Store 0 only for system data
      num_user_stores = Store.num_stores - 1
      if num_user_stores > 0
        index = index_char.hex/(16/num_user_stores)
        if index >= num_user_stores
          index = num_user_stores - 1
        end
        # make up for fact that user store index starts from 1
        index += 1
      end
    end
    index
  end

  def exists?(dockey)
    verify_doctype(dockey)
    Store.get_store(store_index(dockey)).exists?(docname(dockey))
  end

  # Update count for a given document
  def update_count(doctype,count)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).update_count(docname(doctype), count)
  end

  def verify_doctype(doctype)
    # doctype must be in the list (or list must be empty - which is default for 'all documents are valid')
    return true if !self.class.enforce_valid_doctypes or self.class.valid_doctypes.member?(doctype.to_sym) or (self.class.valid_doctypes.size == 0)
    raise Rhoconnect::InvalidDocumentException.new("Invalid document type #{doctype} for #{self.class.name}")
  end

  # interface for doc diffs
  def get_diff_data(srcdoctype, dstdocname, p_size = nil)
    verify_doctype(srcdoctype)
    Store.get_store(store_index(srcdoctype)).get_diff_data(docname(srcdoctype), dstdocname, p_size)
  end

  def get_diff_data_bruteforce(srcdoctype, dstdocname, p_size = nil)
    verify_doctype(srcdoctype)
    Store.get_store(store_index(srcdoctype)).get_diff_data_bruteforce(docname(srcdoctype), dstdocname, p_size)
  end

  def update_elements(doctype, inserts_elements_map, deletes_elements_map)
    verify_doctype(doctype)
    Store.get_store(store_index(doctype)).update_elements(docname(doctype), inserts_elements_map, deletes_elements_map)
  end

  # Computes token for a single client request
  def compute_token(doc_key)
    verify_doctype(doc_key)
    token = get_token
    Store.get_store(store_index(doc_key)).put_value(docname(doc_key),token)
    token.to_s
  end
end
