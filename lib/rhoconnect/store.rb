require 'digest/sha1'
require 'set'
require 'connection_pool'

module Rhoconnect

  class StoreLockException < RuntimeError; end

  class Store
    @@dbs = nil

    class << self
      def nullify
        @@dbs = nil
      end

      def create(server=nil)
        return @@dbs if @@dbs

        if server.is_a?Array
          server.each do |server_string|
            db_inst = RedisImpl.new
            db_inst.create(server_string)
            @@dbs ||= []
            @@dbs << db_inst
          end
        else
          db_inst = RedisImpl.new
          db_inst.create(server)
          @@dbs ||= []
          @@dbs << db_inst
        end
        @@dbs
      end

      def reconnect
        @@dbs.each do |db_inst|
          db_inst.reconnect
        end
      end

      def num_stores
        @@dbs.nil? ? 0 : @@dbs.size
      end

      def get_store(index = 0)
        @@dbs[index]
      end

      def flush_all
        @@dbs.each do |store_instance|
          store_instance.flush_all
        end
      end

      # Deletes all keys matching a given mask
      def flush_data(keymask)
        @@dbs.each do |store|
          store.flush_data(keymask)
        end
      end
      alias_method :flash_data, :flush_data

      def doc_type(dockey)
        get_store(0).db.type(dockey) if dockey
      end

      def set_db_doc(dockey, data, append=false)
        get_store(0).set_db_doc(dockey, data, append)
      end

      def get_db_doc(dockey)
        doc = ""
        @@dbs.each do |store|
          if store.exists?(dockey)
            doc = store.get_db_doc(dockey)
            break
          end
        end
        doc
      end

      def keys(pattern)
        get_store(0).keys(pattern)
      end

      def put_object(dockey, key, data={})
        get_store(0).put_object(dockey, key, data)
      end

      # Adds set with given data, replaces existing set
      # if it exists or appends data to the existing set
      # if append flag set to true
      def put_data(dockey,data={},append=false)
        get_store(0).put_data(dockey, data, append)
      end

      # Same as above, but sets TTL on every key
      def put_tmp_data(dockey,data={},append=false)
        get_store(0).put_tmp_data(dockey, data, append)
      end

      def put_list(dockey, data=[], append=false)
        get_store(0).put_list(dockey, data, append)
      end

      # updates objects for a given doctype, source, user
      # create new objects if necessary
      def update_objects(dockey, data={})
        get_store(0).update_objects(dockey, data)
      end

      # Removes objects from a given doctype,source,user
      def delete_objects(dockey,data=[])
        get_store(0).delete_objects(dockey, data)
      end

      # Deletes data from a given doctype,source,user
      def delete_data(dockey,data={})
        get_store(0).delete_data(dockey, data)
      end

      # Adds a simple key/value pair
      def put_value(dockey,value)
        get_store(0).put_value(dockey, value)
      end

      # Retrieves value for a given key
      def get_value(dockey)
        get_store(0).get_value(dockey)
      end

      def delete_value(dockey)
        get_store(0).delete_value(dockey)
      end

      def incr(dockey)
        get_store(0).incr(dockey)
      end

      def decr(dockey)
        get_store(0).decr(dockey)
      end

      def update_count(dockey, count)
        get_store(0).update_count(dockey, count)
      end

      def get_object(dockey, key)
        get_store(0).get_object(dockey, key)
      end

      def get_objects(dockey, keys)
        get_store(0).get_objects(dockey, keys)
      end

      # Retrieves set for given dockey,source,user
      def get_data(dockey,type=Hash)
        get_store(0).get_data(dockey, type)
      end

      def get_list(dockey)
        get_store(0).get_list(dockey)
      end

      # low-level operations with sorted sets
      def zadd(dockey, score, value)
        get_store(0).zadd(dockey, score, value)
      end

      def zrem(dockey, value)
        get_store(0).zrem(dockey, value)
      end

      def zremrangebyscore(dockey, min_elem, max_elem)
        get_store(0).zremrangebyscore(dockey, min_elem, max_elem)
      end

      def zscore(dockey, value)
        get_store(0).zscore(dockey, value)
      end

      def zrevrange(dockey, start, stop)
        get_store(0).zrevrange(dockey, start, stop)
      end

      def zrange(dockey, start, stop)
        get_store(0).zrange(dockey, start, stop)
      end

      # Retrieves diff data hash between two sets
      # each entry is in the form of DIFF_OBJ_ELEMENT => [OBJ_KEY, OBJ_DATA_PAIRS]
      def get_diff_data(src_dockey,dst_dockey,p_size=nil)
        get_store(0).get_diff_data(src_dockey, dst_dockey, p_size)
      end

      # Retrieves diff data hash between two sets by using BruteForce approach
      # => download both sets from Redis and compute diffs inside of Ruby
      # worst-cast scenario - it is much slower than doing Redis sdiff
      # but : it allows Redis clustering
      # each entry is in the form of DIFF_OBJ_ELEMENT => [OBJ_KEY, OBJ_DATA_PAIRS]
      def get_diff_data_bruteforce(src_dockey,dst_dockey,p_size=nil)
        get_store(0).get_diff_data_bruteforce(src_dockey, dst_dockey, p_size)
      end

      def get_inserts_deletes(inserts_elements_map, deletes_elements_map)
        get_store(0).get_inserts_deletes(inserts_elements_map, deletes_elements_map)
      end

      def update_elements(dockey, inserts_elements_map, deletes_elements_map)
        get_store(0).update_elements(dockey, inserts_elements_map, deletes_elements_map)
      end

      # Lock a given key and release when provided block is finished
      def lock(dockey,timeout=0,raise_on_expire=false, &block)
        get_store(0).lock(dockey, timeout, raise_on_expire, &block)
      end

      def get_lock(dockey,timeout=0,raise_on_expire=false)
        get_store(0).get_lock(dockey, timeout, raise_on_expire)
      end

      def release_lock(dockey,lock,raise_on_expire=false)
        get_store(0).release_lock(dockey, lock, raise_on_expire)
      end

      # Create a copy of srckey in dstkey
      def clone(srckey,dstkey)
        get_store(0).clone(srckey, dstkey)
      end

      # Rename srckey to dstkey
      def rename(srckey,dstkey)
        get_store(0).rename(srckey, dstkey)
      end

      # Rename srckey to dstkey
      def rename_tmp_data(srckey,dstkey)
        get_store(0).rename_tmp_data(srckey, dstkey)
      end


      def put_zdata(dockey,assoc_key,data=[],append=false)
        get_store(0).put_zdata(dockey, assoc_key, data, append)
      end

      # Retrieves set for given dockey,associated key (client_id), obj_hashes
      def get_zdata(dockey)
        get_store(0).get_zdata(dockey)
      end

      # Deletes all keys and their hashes from the Redis DB
      def flush_zdata(dockey)
        get_store(0).flush_zdata(dockey)
      end

      def exists?(key)
        get_store(0).exists?(key)
      end

      alias_method :set_value, :put_value
      alias_method :set_data, :put_data
    end
  end

  class RedisImpl
    RESERVED_ATTRIB_NAMES = ["attrib_type", "id"] unless defined? RESERVED_ATTRIB_NAMES
    @db = nil

    def create(server=nil)
      @db ||= _get_redis(server)
      raise "Error connecting to Redis store." unless @db and
        (@db.is_a?(Redis) or @db.is_a?(Redis::Client) or @db.is_a?(ConnectionPool::Wrapper))
    end

    def reconnect
      @db.client.reconnect
    end

    def flush_all
      @db.flushdb
    end

    def start_transaction
      @db.multi
    end

    def execute_transaction
      @db.exec
    end

    def doc_type(dockey)
      @db.type(dockey) if dockey
    end

    def set_db_doc(dockey, data, append=false)
      if data.is_a?(String)
        put_value(dockey, data)
      else
        put_data(dockey, data, append)
      end
    end

    def get_db_doc(dockey)
      doctype = doc_type(dockey)
      if doctype == 'string'
        get_value(dockey)
      elsif doctype == 'list'
        get_data(dockey, Array).to_json
      elsif doctype == 'zset'
        get_zdata(dockey).to_json
      else
        get_data(dockey).to_json
      end
    end

    def put_object(dockey, key, data={})
      _put_objects(dockey, {key => data})
    end

    # Same as above, but sets TTL on every key
    def put_tmp_data(dockey,data={},append=false)
      put_data(dockey, data, append, Rhoconnect.store_key_ttl)
    end

      # Adds set with given data, replaces existing set
    # if it exists or appends data to the existing set
    # if append flag set to true
    # if ttl > 0 - sets expriration time on the keys
    def put_data(dockey,data={},append=false, ttl=0)
      if dockey and data
        flush_data(dockey) unless append
        # Inserts a hash or array
        if data.is_a?Hash
          _put_objects(dockey, data, ttl)
        else
          put_list(dockey,data,append, ttl)
        end
      end
      true
    end

    def put_list(dockey, data=[], append=false, ttl=0)
      if dockey and data
        flush_data(dockey) unless append
        @db.pipelined do
          data.each do |element|
            @db.rpush(dockey, element)
          end
          @db.expire(dockey, ttl) if ttl > 0
        end
      end
      true
    end

    # updates objects for a given doctype, source, user
    # create new objects if necessary
    def update_objects(dockey, data={})
      return 0 unless dockey and data

      new_object_count = 0
      objs = get_objects(dockey, data.keys) || {}

      collected_adds = {}
      collected_rems = {}
      # my_bucket = nil
      @db.pipelined do
        data.each do |key,obj|
          is_create = objs[key].nil?
          new_object_count += 1 if is_create
          obj_bucket = _add_bucket_index(dockey, "#{_create_obj_index(key)}")

          # collect SREM (if object exists in DB)
          unless is_create
            old_element = set_obj_element(key,objs[key])
            collected_rems[obj_bucket] ||= []
            collected_rems[obj_bucket] << old_element
          end
          # update the object and collect SADD
          objs[key] ||= {}
          objs[key].merge!(obj)

          new_element = set_obj_element(key,objs[key])
          collected_adds[obj_bucket] ||= []
          collected_adds[obj_bucket] << new_element
        end
        # process all SADD and SREM commands as one
        # SREM must go first
        collected_rems.each do |bucket, bucket_data|
          @db.srem(bucket, bucket_data)
        end
        collected_adds.each do |bucket, bucket_data|
          @db.sadd(bucket, bucket_data)
        end
      end


      #data1 = @db.smembers(my_bucket)
      #puts "data1 is #{data1.inspect}"

      new_object_count
    end

    # Removes objects from a given doctype,source,user
    def delete_objects(dockey,data=[])
      return 0 unless dockey and data

      objs = get_objects(dockey, data)
      _delete_objects(dockey, objs)
    end

    # Deletes data from a given doctype,source,user
    def delete_data(dockey,data={})
      if dockey and data
        _delete_objects(dockey, data)
      end
      true
    end

    # Adds a simple key/value pair
    def put_value(dockey,value)
      if dockey
        if value
          @db.set(dockey,value.to_s)
        else
          @db.del(dockey)
        end
      end
    end

    # Retrieves value for a given key
    def get_value(dockey)
      @db.get(dockey) if dockey
    end

    def delete_value(dockey)
      @db.del(dockey)
    end

    def incr(dockey)
      @db.incr(dockey)
    end

    def decr(dockey)
      @db.decr(dockey)
    end

    def update_count(dockey, count)
      @db.incrby(dockey, count)
    end

    def get_object(dockey, key)
      res = _get_objects(dockey, [key])
      (res and res.size > 0) ? res.values[0] : nil
    end

    def get_objects(dockey, keys)
      _get_objects(dockey, keys)
    end

    # Retrieves set for given dockey,source,user
    def get_data(dockey,type=Hash)
      res = type == Hash ? {} : []
      if dockey
        if type == Hash
          buckets = _get_buckets(dockey)
          members = @db.pipelined do
            buckets.each do |bucket|
              @db.smembers(bucket)
            end if buckets
          end
          members.each do |elements|
            elements.each do |element|
              key,obj = get_obj_element(element)
              res[key] = obj
              #res[key].merge!({attrib => value})
            end if elements
          end if members
        else
          res = get_list(dockey)
        end
      end
      res
    end

    def get_list(dockey)
      res = []
      if dockey
        res = @db.lrange(dockey, 0, -1)
      end
      res
    end

    # Retrieves diff data hash between two sets
    # each entry is in the form of DIFF_OBJ_ELEMENT => [OBJ_KEY, OBJ_DATA_PAIRS]
    def get_diff_data(src_dockey,dst_dockey,p_size=nil)
      res = {}
      return res if p_size == 0
      # return immediately if p_size == 0
      # NOTE: 0 and nil are different, nil means - return all diffs
      if src_dockey and dst_dockey
        # obtain combined indices
        indices = @db.hgetall("#{dst_dockey}:indices")
        indices.keys.each do |index|
          dst_bucket_name = "#{dst_dockey}:#{index}"
          src_bucket_name = "#{src_dockey}:#{index}"
          diff_elements =  @db.sdiff(dst_bucket_name,src_bucket_name)
          diff_elements.each do |element|
            keypairs = get_obj_key_and_pairs(element)
            next unless keypairs
            res[element] = keypairs
            return res if p_size and (res.size >= p_size)
          end
        end
      end
      res
    end

    # Retrieves diff data hash between two sets by using BruteForce approach
    # => download both sets from Redis and compute diffs inside of Ruby
    # worst-cast scenario - it is much slower than doing Redis sdiff
    # but : it allows Redis clustering
    # each entry is in the form of DIFF_OBJ_ELEMENT => [OBJ_KEY, OBJ_DATA_PAIRS]
    def get_diff_data_bruteforce(src_dockey,dst_dockey,p_size=nil)
      inserts = {}
      deletes = {}
      # return immediately if p_size == 0
      # NOTE: 0 and nil are different, nil means - return all diffs
      return res if p_size == 0
      if src_dockey and dst_dockey
        # obtain combined indices
        indices = @db.hgetall("#{dst_dockey}:indices")
        indices.merge!(@db.hgetall("#{src_dockey}:indices"))
        indices.keys.each do |index|
          dst_bucket_name = "#{dst_dockey}:#{index}"
          src_bucket_name = "#{src_dockey}:#{index}"
          src_elements =  Set.new(@db.smembers(src_bucket_name))
          dst_elements = Set.new(@db.smembers(dst_bucket_name))

          insert_diff_elements = dst_elements.dup.subtract(src_elements) unless p_size and (inserts.size >= p_size)
          delete_diff_elements = src_elements.dup.subtract(dst_elements) unless p_size and (deletes.size >= p_size)

          insert_diff_elements.each do |element|
            keypairs = get_obj_key_and_pairs(element)
            next unless keypairs
            inserts[element] = keypairs
            break if p_size and (inserts.size >= p_size)
          end if insert_diff_elements

          delete_diff_elements.each do |element|
            keypairs = get_obj_key_and_pairs(element)
            next unless keypairs
            deletes[element] = keypairs
            break if p_size and (deletes.size >= p_size)
          end if delete_diff_elements

          break if p_size and (inserts.size >= p_size) and (deletes.size >= p_size)
        end
      end
      [inserts, deletes]
    end

    def get_inserts_deletes(inserts_elements_map, deletes_elements_map)
      inserts_obj_hash = {}
      inserts_elements_map.each do |element,keypairs|
        key,obj_pairs = keypairs[0],keypairs[1]
        next unless (key and obj_pairs)
        inserts_obj_hash[key] = Set.new(obj_pairs)
      end

      deletes_obj_hash = {}
      deletes_elements_map.each do |element,keypairs|
        key,obj_pairs = keypairs[0],keypairs[1]
        next unless (key and obj_pairs)
        deletes_obj_hash[key] = Set.new(obj_pairs)
      end
      # modified attributes
      inserts = {}
      deletes = {}

      inserts_obj_hash.each do |key, obj_set|
        deletes_pairs = nil
        inserts_pairs = nil
        if deletes_obj_hash.has_key?(key)
          deletes_pairs = deletes_obj_hash[key].dup.subtract(obj_set).to_a
          inserts_pairs = obj_set.dup.subtract(deletes_obj_hash[key]).to_a
          # remove the key from the deletes set - we already processed it
          deletes_obj_hash.delete(key)
        else
          # if object is not in the deletes set - then, it's all inserts
          inserts_pairs = obj_set.to_a
        end
        # split resulting pairs
        if inserts_pairs and inserts_pairs.size > 0
          inserts[key] = split_obj_pairs(inserts_pairs)
        end
        if deletes_pairs and deletes_pairs.size > 0
          deletes[key] = split_obj_pairs(deletes_pairs)
        end
      end
      # after we analyzed the inserts__obj_hash
      # => deletes_obj_hash should contain only the unmatched deletes
      deletes_obj_hash.each do |key, obj_set|
        if obj_set.size > 0
          deletes[key] = split_obj_pairs(obj_set.to_a)
        end
      end

      [inserts, deletes]
    end

    def update_elements(dockey, inserts_elements_map, deletes_elements_map)
      indices_to_cleanup = Set.new
      @db.pipelined do
        collected_adds = {}
        collected_rems = {}

        inserts_elements_map.each do |element,keypairs|
          key = keypairs[0]
          next if not key or not element or element.size == 0

          obj_bucket_index = _create_obj_index(key)
          bucket_name = "#{dockey}:#{obj_bucket_index}"
          _add_bucket_index(dockey, obj_bucket_index)

          collected_adds[bucket_name] ||= []
          collected_adds[bucket_name] << element
        end

        deletes_elements_map.each do |element,keypairs|
          key = keypairs[0]
          next if not key or not element or element.size == 0

          obj_bucket_index = _create_obj_index(key)
          bucket_name = "#{dockey}:#{obj_bucket_index}"
          indices_to_cleanup << bucket_name

          collected_rems[bucket_name] ||= []
          collected_rems[bucket_name] << element
        end

        # now, perform SREM first, then SADD
        collected_rems.each do |bucket, bucket_data|
          @db.srem(bucket, bucket_data)
        end
        collected_adds.each do |bucket,bucket_data|
          @db.sadd(bucket, bucket_data)
        end
      end
      # now, cleanup buckets if necessary
      _cleanup_buckets(dockey, indices_to_cleanup.to_a)
    end

    def keys(pattern)
      @db.keys(pattern)
    end

    # Deletes all keys matching a given mask
    def flush_data(keymask)
      if keymask.to_s[/[*\[\]?]/]
        # If the keymask contains any pattern matching characters
        # Use keys command to find all keys matching pattern (this is extremely expensive)
        # Then delete matches
        keys(keymask).each do |key|
          _delete_doc(key)
        end
      else
        # The keymask doesn't contain pattern matching characters
        # A delete call is all that is needed
        _delete_doc(keymask)
      end
    end
    alias_method :flash_data, :flush_data

    # Lock a given key and release when provided block is finished
    def lock(dockey,timeout=0,raise_on_expire=false, &block)
      m_lock = get_lock(dockey,timeout,raise_on_expire)
      res = yield
      release_lock(dockey,m_lock)
      res
    end

    def get_lock(dockey,timeout=0,raise_on_expire=false)
      lock_key = _lock_key(dockey)
      current_time = Time.now.to_i
      ts = current_time+(Rhoconnect.lock_duration || timeout)+1
      loop do
        if not @db.setnx(lock_key,ts)
          current_lock = @db.get(lock_key)
          # ensure lock wasn't released between the setnx and get calls
          if current_lock
           	current_lock_timeout = current_lock.to_i
            if raise_on_expire or Rhoconnect.raise_on_expired_lock
           	  if current_lock_timeout <= current_time
           	    # lock expired before operation which set it up completed
           	    # this process cannot continue without corrupting locked data
           	    raise StoreLockException, "Lock \"#{lock_key}\" expired before it was released"
           	  end
           	else
           	  if current_lock_timeout <= current_time and
           	    @db.getset(lock_key,ts).to_i <= current_time
           	    # previous lock expired and we replaced it with our own
           	    break
           	  end
            end
       	  # lock was released between setnx and get - try to acquire it again
     	    elsif @db.setnx(lock_key,ts)
       	    break
          end
          sleep(1)
          current_time = Time.now.to_i
        else
          break #no lock was set, so we set ours and leaving
        end
      end
      return ts
    end

    # Due to redis bug #140, setnx always returns true so this doesn't work
    # def get_lock(dockey,timeout=0)
    #   lock_key = _lock_key(dockey)
    #   until @db.setnx(lock_key,1) do
    #     sleep(1)
    #   end
    #   @db.expire(lock_key,timeout+1)
    #   Time.now.to_i+timeout+1
    # end

    def release_lock(dockey,lock,raise_on_expire=false)
      @db.del(_lock_key(dockey)) if raise_on_expire or Rhoconnect.raise_on_expired_lock or (lock >= Time.now.to_i)
    end

    # Create a copy of srckey in dstkey
    def clone(srckey,dstkey)
      buckets = _get_bucket_indices(srckey)
      if buckets.size
        @db.pipelined do
          buckets.each do |bucket_index|
            _add_bucket_index(dstkey, bucket_index)
            @db.sdiffstore("#{dstkey}:#{bucket_index}", "#{srckey}:#{bucket_index}", '')
          end
        end
      else
        @db.sdiffstore(dstkey,srckey,'')
      end
    end

    # Rename temp doc srckey to persist dstkey
    def rename_tmp_data(srckey,dstkey)
      rename(srckey,dstkey,true)
    end

    # Rename srckey to dstkey
    # also, removes TTL if ordered (normally - it is not necessary)
    def rename(srckey,dstkey,make_persist=false)
      buckets = _get_bucket_indices(srckey)
      if buckets.size
        @db.pipelined do
          @db.del("#{srckey}:indices")
          buckets.each do |bucket_index|
            _add_bucket_index(dstkey, bucket_index)
            @db.rename("#{srckey}:#{bucket_index}", "#{dstkey}:#{bucket_index}")
          end
          if make_persist
            @db.persist("#{dstkey}:indices")
            buckets.each do |bucket_index|
              @db.persist("#{dstkey}:#{bucket_index}")
            end
          end
        end
      else
        if @db.exists(srckey)
          @db.rename(srckey,dstkey)
          @db.persist(dstkey) if make_persist
        end
      end
    end

    def put_zdata(dockey,assoc_key,data=[],append=false)
      return true unless (dockey and assoc_key and data)
      flush_zdata(dockey) unless append
      current_score = 0
      current_score_data = @db.zrevrange(dockey,0,0,:with_scores => true)
      current_score = current_score_data[-1][1].to_i if current_score_data and current_score_data[-1]
      current_score += 1

      data.each_with_index do |source_queue_entry, source_entry_index|
        source_id = source_queue_entry[0]
        source_id_with_index = "#{source_id}:#{source_entry_index}"
        source_entry_data = source_queue_entry[1]
        source_entry_docname = setelement(current_score,assoc_key, source_id_with_index)
        source_entry_data.each_with_index do |obj_entry, obj_index|
          obj_key_with_index = "#{obj_index}_#{obj_entry[0]}"
          put_data("#{dockey}:#{source_entry_docname}",{obj_key_with_index => obj_entry[1]},true)
        end if source_entry_data
        @db.zadd(dockey, current_score, source_entry_docname)
      end if data
      true
    end

    # Retrieves set for given dockey,associated key (client_id), obj_hashes
    def get_zdata(dockey)
      data = @db.zrange(dockey, 0, -1)
      ret = []
      assoc_keys = []
      scores = []
      data.each do |zsetkey|
        obj_entries = []
        obj_hash = get_data "#{dockey}:#{zsetkey}"
        obj_hash.each do |obj_key_with_index, objdata|
          index,objkey = obj_key_with_index.split('_', 2)
          obj_entries[index.to_i] = [objkey, objdata]
        end
        score,assoc_key,source_id_with_index = getelement(zsetkey)
        source_id, source_index = source_id_with_index.split(':', 2)

        if scores[-1] != score
          ret << [[source_id, obj_entries]]
          assoc_keys << assoc_key
          scores << score
        else
          ret[-1] << [source_id, obj_entries]
        end
      end if data
      [ret, assoc_keys]
    end

    # Deletes all keys and their hashes from the Redis DB
    def flush_zdata(dockey)
      data = @db.zrange(dockey, 0, -1)
      data.each do |zsetkey|
        _delete_doc("#{dockey}:#{zsetkey}")
      end
      @db.zremrangebyrank(dockey, 0, -1)
    end

    def exists?(key)
      @db.exists(key) || @db.exists("#{key}:indices")
    end

    # low-level operations with sorted sets
    def zadd(dockey, score, value)
      @db.zadd(dockey, score, value)
    end

    def zrem(dockey, value)
      @db.zrem(dockey, value)
    end

    def zremrangebyscore(dockey, min_elem, max_elem)
      @db.zremrangebyscore(dockey, min_elem, max_elem)
    end

    def zscore(dockey, value)
      @db.zscore(dockey, value)
    end

    def zrevrange(dockey, start, stop)
      @db.zrevrange(dockey, start, stop)
    end

    def zrange(dockey, start, stop)
      @db.zrange(dockey, start, stop)
    end

    alias_method :set_value, :put_value
    alias_method :set_data, :put_data

    # This method should never be accessed by anything except specs
    def db
      return @db
    end

    private

    def _get_redis(server=nil)
      url = ENV[REDIS_URL] || ENV[REDISTOGO_URL] || nil
      if url
        Rhoconnect.redis_url = url
        ConnectionPool::Wrapper.new(:size => Rhoconnect.connection_pool_size,
                                    :timeout => Rhoconnect.connection_pool_timeout) do
          Redis.connect(:url => url, :timeout => Rhoconnect.redis_timeout, :thread_safe => true)
        end
      elsif server and server.is_a?(String)
        Rhoconnect.redis_url = "redis://#{server}"
        host,port,db,password = server.split(':')
        ConnectionPool::Wrapper.new(:size => Rhoconnect.connection_pool_size,
                                    :timeout => Rhoconnect.connection_pool_timeout) do
          host = '127.0.0.1' if host == 'localhost'
          Redis.connect(
            :thread_safe => true,
            :host => host,
            :port => port,
            :db => db,
            :password => password,
            :timeout => Rhoconnect.redis_timeout
          )
        end
      elsif server and (server.is_a?(Redis) or server.is_a?(ConnectionPool::Wrapper))
        server
      else
        Rhoconnect.redis_url = "redis://localhost:6379"
        ConnectionPool::Wrapper.new(:size => 5, :timeout => 30) do
          Redis.connect(:timeout => 30, :thread_safe => true)
        end
      end
    end

    def _lock_key(dockey)
      "lock:#{dockey}"
    end

    def _is_reserved?(attrib,value) #:nodoc:
      RESERVED_ATTRIB_NAMES.include? attrib
    end

    # operations with docs that are split into buckets
    def _delete_doc(dockey)
      # check if this doc has buckets
      if(@db.exists("#{dockey}:indices"))
        buckets_list = _get_buckets(dockey)
        # delete all buckets
        @db.pipelined do
          @db.del("#{dockey}:indices")
          buckets_list.each do |bucket|
            @db.del(bucket)
          end
        end
      end

      # delete main doc
      @db.del(dockey)
    end

    # create object's bucket index
    # using SHA1 hashing
    def _create_obj_index(key)
      Digest::SHA1.hexdigest(key)[0..1]
    end

    def _add_bucket_index(dockey, bucket_index)
      bucket_name = "#{dockey}:#{bucket_index}"
      @db.hsetnx("#{dockey}:indices", bucket_index, bucket_name)
      bucket_name
    end

    def _remove_bucket_index(dockey, bucket_index)
      @db.hdel("#{dockey}:indices", bucket_index)
    end

    def _get_bucket_indices(dockey)
      @db.hkeys("#{dockey}:indices")
    end

    def _get_buckets(dockey)
      @db.hvals("#{dockey}:indices")
    end

    def _cleanup_buckets(dockey, indices_to_cleanup)
      indices_to_cleanup.each do |index|
        bucket_name = "#{dockey}:#{index}"
        _remove_bucket_index(dockey, index) unless @db.exists(bucket_name)
      end if indices_to_cleanup
    end

    def _put_objects(dockey, data={}, ttl=0)
      return if data.empty? or not dockey

      collected_adds = {}
      @db.pipelined do
        data.each do |key,obj|
          raise ArgumentError, "Invalid value object: #{obj.inspect}. Hash is expected." unless obj.is_a?(Hash)
          next if obj.empty? or not key

          obj_bucket_index = _create_obj_index(key)
          bucket_name = "#{dockey}:#{obj_bucket_index}"
          _add_bucket_index(dockey, obj_bucket_index)
          collected_adds[bucket_name] ||= []
          collected_adds[bucket_name] << set_obj_element(key, obj)

        end
        # all SADD operations on a bucket key
        # are combined into one - it proves to perform faster
        collected_adds.each do |bucket,bucket_data|
          @db.sadd(bucket, bucket_data)
          if ttl > 0
            @db.expire(bucket, ttl)
          end
        end
        @db.expire("#{dockey}:indices", ttl) if ttl > 0
      end
    end

    def _delete_objects(dockey, data={})
      return 0 if data.empty? or not dockey

      deleted_object_count = 0
      indices_to_cleanup = Set.new
      collected_rems = {}
      @db.pipelined do
        data.each do |key, obj|
          next if obj.empty? or not key
          obj_bucket_index = _create_obj_index(key)
          bucket_name = "#{dockey}:#{obj_bucket_index}"
          indices_to_cleanup << obj_bucket_index

          collected_rems[bucket_name] ||= []
          collected_rems[bucket_name] << set_obj_element(key, obj)
          deleted_object_count += 1
        end

        # all SREM operations on a bucket
        # are combined into one
        collected_rems.each do |bucket,bucket_data|
          @db.srem(bucket, bucket_data)
        end
      end
      _cleanup_buckets(dockey, indices_to_cleanup.to_a)
      deleted_object_count
    end

    def _get_objects(dockey, keys)
      return nil unless dockey
      res = nil
      keys_map = Set.new
      buckets = Set.new
      keys.each do |key|
        obj_bucket_index = _create_obj_index(key)
        bucket_name = "#{dockey}:#{obj_bucket_index}"
        keys_map << key
        buckets << bucket_name
      end
      members = @db.pipelined do
        buckets.to_a.each do |bucket_name|
          @db.smembers(bucket_name)
        end
      end
      members.each do |bucket_data|
        bucket_data.each do |element|
          key,pairs = get_obj_key_and_pairs(element)
          next unless keys_map.include?(key)
          obj = split_obj_pairs(pairs)
          next if obj.empty?
          res ||= {}
          res[key] = obj
        end if bucket_data
      end if members
      res
    end

    # operations on object elements
    def get_obj_element(elem)
      key,pairs = get_obj_key_and_pairs(elem)
      return unless (key and pairs)
      [key,split_obj_pairs(pairs)]
    end
    def get_obj_key_and_pairs(elem)
      pairs = elem.split(":^rho&:")
      return unless pairs
      [pairs[0], pairs[1..-1]]
    end
    def split_obj_pairs(pairs)
      obj = {}
      pairs.each do |pair|
        attrib,value = pair.split(':',2)
        obj[attrib] = value
      end
      obj
    end

# Set Obj Element MUST ensure the order of attribs
# in Ruby 1.9.x Hash keys are sorted (always in the same order), so
# we do not need to do redundant sorting
    def set_obj_element(key, obj)
      return unless (key and key.size > 0 and obj and obj.size > 0)
      elem = "#{key}"
      obj.each do |attrib, value|
        unless _is_reserved?(attrib,value)
          elem += ":^rho&:#{attrib}:#{value}"
        end
      end
      elem
    end
  end
end
