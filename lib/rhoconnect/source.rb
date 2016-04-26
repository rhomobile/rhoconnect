module Rhoconnect
  class MemoryOrm
    @@model_data = {}
    @@string_fields = []
    @@integer_fields = []
    attr_accessor :id

    class << self
      attr_accessor :validates_presence

      def create(fields,params)
        if self.validates_presence
          self.validates_presence.each do |field|
            raise ArgumentError.new("Missing required field '#{field}'") unless fields[field]
          end
        end
      end

      def define_fields(string_fields = [], integer_fields = [])
        @@string_fields,@@integer_fields = string_fields,integer_fields
        integer_fields.each do |attrib|
          define_method("#{attrib}=") do |value|
            value = (value.nil?) ? nil : value.to_i
            @@model_data[self.name.to_sym][attrib.to_sym] = value
          end
          define_method("#{attrib}") do
            @@model_data[self.name.to_sym][attrib.to_sym]
          end
        end
        string_fields.each do |attrib|
          define_method("#{attrib}=") do |value|
            attrib = attrib.to_sym
            name = nil
            if attrib == :name
              instance_variable_set(:@name, value)
              name = value
            else
              name = self.name
            end
            @@model_data[name.to_sym] ||= {} # TODO: shouldn't be nil here
            @@model_data[name.to_sym][attrib] = value
          end
          define_method("#{attrib}") do
            @@model_data[instance_variable_get(:@name).to_sym][attrib.to_sym]
          end
          # we have separate methods for this
          @@integer_fields << :poll_interval unless @@integer_fields.include?(:poll_interval)
        end
      end

      def validates_presence_of(*names)
        self.validates_presence ||= []
        names.each do |name|
          self.validates_presence << name
        end
      end

      def is_exist?(id)
        !@@model_data[id.to_sym].nil?
      end

      def class_prefix(classname)
        classname.to_s.
          sub(%r{(.*::)}, '').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          downcase
      end
    end

    def update_fields(fields)
      fields.each do |name,value|
        arg = "#{name}=".to_sym
        self.send(arg, value)
      end
    end

    def to_array
      res = []
      @@string_fields.each do |field|
        res << {"name" => field, "value" => send(field.to_sym), "type" => "string"}
      end
      @@integer_fields.each do |field|
        res << {"name" => field, "value" => send(field.to_sym), "type" => "integer"}
      end
      res
    end

    def to_hash
      res = {}
      @@string_fields.each do |field|
       res[field] = send(field.to_sym)
      end
      @@integer_fields.each do |field|
       res[field] = send(field.to_sym)
      end
      res
    end
  end

  class Source < MemoryOrm
    attr_accessor :app_id, :user_id

    validates_presence_of :name

    include Document
    include LockOps

    # source fields
    define_fields([:id, :rho__id, :name, :url, :login, :password, :callback_url, :partition_type, :sync_type,
      :queue, :query_queue, :cud_queue, :belongs_to, :has_many, :pass_through, :push_notify], [:source_id, :priority, :retry_limit, :simulate_time])

    define_valid_doctypes([:md,
                          :md_size,
                          :md_copy,
                          :errors,
                          :metadata,
                          :metadata_sha1,
                          :schema,
                          :schema_sha1])

    def initialize(fields)
      self.name = fields['name'] || fields[:name]
      update_fields(fields)
    end

    def to_hash
      res = super
      res.merge({:user_id=>self.user_id,:app_id=>self.app_id})
    end

    def self.set_defaults(fields)
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:partition_type] = fields[:partition_type] ? fields[:partition_type].to_sym : :user
      fields[:poll_interval] ||= 300
      fields[:sync_type] = fields[:sync_type] ? fields[:sync_type].to_sym : :incremental
      fields[:id] = fields[:name]
      fields[:rho__id] = fields[:name]
      fields[:belongs_to] = fields[:belongs_to].to_json if fields[:belongs_to]
      fields[:schema] = fields[:schema].to_json if fields[:schema]
      fields[:retry_limit] = fields[:retry_limit] ? fields[:retry_limit] : 0
      fields[:simulate_time] = fields[:simulate_time] ? fields[:simulate_time] : 0
      fields[:push_notify] = fields[:push_notify] ? fields[:push_notify] : 'false'
    end

    def store_index(doctype)
      # app-partitioned sources go to 0
      # everything else if sharded
      compute_store_index(doctype, self, self.user_id)
    end

    def self.create(fields,params)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      super(fields,params)
      @@model_data[fields[:name].to_sym] = {}
      set_defaults(fields)
      obj = new(fields)
      obj.assign_args(params)
      obj
    end

    def self.load(obj_id,params)
      validate_attributes(params)

      # if source is pre-defined
      # create it dynamically here
      Rhoconnect.create_predefined_source(obj_id,params)

      model_hash = @@model_data[obj_id.to_sym]

      obj = new(model_hash) if model_hash
      if obj
        obj = obj.dup
        obj.assign_args(params)
      end
      obj
    end

    def self.update_associations(sources)
      params = {:app_id => APP_NAME,:user_id => '*'}
      sources.each { |source| Source.load(source, params).has_many = nil }
      sources.each do |source|
        s = Source.load(source, params)
        if s.belongs_to
          belongs_to = JSON.parse(s.belongs_to)
          if belongs_to.is_a?(Array)
            belongs_to.each do |entry|
              attrib = entry.keys[0]
              model = entry[attrib]
              owner = Source.load(model, params)
              owner.has_many ||= ''
              owner.has_many = owner.has_many+',' if owner.has_many.length > 0
              owner.has_many += [source,attrib].join(',')
            end
          else
            log "WARNING: Incorrect belongs_to format for #{source}, belongs_to should be an array."
          end
        end
      end
    end

    def self.delete_all
      params = {:app_id => APP_NAME,:user_id => '*'}
      @@model_data.each do |k,v|
        s = Source.load(k,params)
        s.flush_store_data
        Store.flush_data("source:#{s.name}:*")
      end
      @@model_data = {}
    end

    def assign_args(params)
      self.user_id = params[:user_id]
      self.app_id = params[:app_id]
    end

    def blob_attribs
      return '' unless self.schema
      schema = JSON.parse(self.schema)
      blob_attribs = []
      schema['property'].each do |key,value|
        values = value ? value.split(',') : []
        if values.include?('blob')
          attrib = key.dup
          attrib << "," + (values.include?('overwrite') ? '1' : '0')
          blob_attribs << attrib
        end
      end
      blob_attribs.sort.join(',')
    end

    def update(fields)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      self.class.set_defaults(fields)
    end

    def poll_interval
      value = Store.get_value(poll_interval_key)
      value ? value.to_i : nil
    end

    def poll_interval=(interval)
      Store.put_value(poll_interval_key, interval)
    end

    # Return the user associated with a source
    def user
      User.load(self.user_id)
    end

    # Return the app the source belongs to
    def app
      App.load(self.app_id)
    end

    def schema
      self.get_value(:schema)
    end

    def read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      load_read_state || ReadState.create(id)
    end

    def load_read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      ReadState.load(id)
    end

    def delete_user_read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      ReadState.delete_user(id)
    end

    def doc_suffix(doctype)
      "#{user_by_partition}:#{self.name}:#{doctype.to_s}"
    end

    def flush_store_data
      delete_user_read_state
      self.class.valid_doctypes.each do |docname, doctype|
        case doctype
        when :queue
          flush_queue(docname)
        when :document
          flush_data(docname)
        end
      end
    end

    def queue_docname(dockey)
      # currently, all queues are bound by user - not shared
      "#{self.class.class_prefix(self.class)}:#{self.app_id}:#{self.name}:#{dockey.to_s}"
    end

    # this data is not sharded
    def lock_queue_doc(doctype)
      Store.lock(queue_docname(doctype)) do
        yield self
      end
    end

    # this is an atomic operation
    # - lock queue, get queue data, flush queue, unlock queue
    def process_queue(doctype)
      verify_doctype(doctype)
      ret = []
      keys = []
      lock_queue_doc(doctype) do |s|
        ret, keys = Store.get_store(0).get_zdata(s.queue_docname(doctype))
        Store.get_store(0).flush_zdata(s.queue_docname(doctype))
      end
      [ret, keys]
    end

    def get_queue(doctype)
      verify_doctype(doctype)
      ret = []
      keys = []
      lock_queue_doc(doctype) do |s|
        ret, keys = Store.get_store(0).get_zdata(s.queue_docname(doctype))
      end
      [ret, keys]
    end

    def flush_queue(doctype)
      verify_doctype(doctype)
      lock_queue_doc(doctype) do |s|
        Store.get_store(0).flush_zdata(s.queue_docname(doctype))
      end
    end

    def push_queue(doctype,assoc_key, data=[],append=false)
      verify_doctype(doctype)
      lock_queue_doc(doctype) do |s|
        Store.get_store(0).put_zdata(s.queue_docname(doctype),assoc_key, data,append)
      end
    end

    def delete
      flush_store_data
      @@model_data.delete(rho__id.to_sym) if rho__id
    end

    def partition
      self.partition_type.to_sym
    end

    def partition=(value)
      self.partition_type = value
    end

    def user_by_partition
      self.partition.to_sym == :user ? partition_name : '__shared__'
    end

    def partition_name
      # edge case - used in deleting documents
      return self.user_id if self.user_id == '*'
      # default is user_id
      pname = self.user_id
      begin
        model_klass = Rhoconnect::Model::Base.load_source_model(self)
        pname = model_klass ? model_klass.partition_name(self.user_id) : self.user_id
      # eat the exception here
      rescue Exception #=> e
      end
      pname
    end

    def check_refresh_time
      self.poll_interval == 0 or
      (self.poll_interval != -1 and self.read_state.refresh_time <= Time.now.to_i)
    end

    def if_need_refresh(client_id=nil,params=nil)
      need_refresh = lock(:md) do |s|
        check = check_refresh_time
        self.read_state.prev_refresh_time = self.read_state.refresh_time if check
        self.read_state.refresh_time = Time.now.to_i + self.poll_interval if check
        check
      end
      yield client_id,params if need_refresh
    end

    def rewind_refresh_time(query_failure)
      return if self.poll_interval == 0
      lock(:md) do |s|
        rewind_time = false
        # reset number of retries
        # and prev_refresh_time on succesfull query
        # or if last refresh was more than 'poll_interval' time ago
        if not query_failure or ((Time.now.to_i - self.read_state.prev_refresh_time) >= self.poll_interval)
          # we need to reset the prev_refresh_time here
          # otherwise in case of expired poll interval
          # and repeating failures - it will reset the counter
          # on every error
          self.read_state.prev_refresh_time = Time.now.to_i
          self.read_state.retry_counter = 0
        end

        # rewind the refresh time on failure
        # if retry limit is not reached
        if query_failure
          if self.read_state.retry_counter < self.retry_limit
            self.read_state.increment!(:retry_counter)
            rewind_time = true
            # we have reached the limit - do not rewind the refresh time
            # and reset the counter
          else
            self.read_state.retry_counter = 0
          end
        end

        if rewind_time
          self.read_state.refresh_time = self.read_state.prev_refresh_time
        end
      end
    end

    def is_pass_through?
      self.pass_through and self.pass_through.to_s == 'true'
    end

    def push_notify?
      self.push_notify and self.push_notify.to_s == 'true'
    end

    def announce_changes
      return unless push_notify?
      # TODO: currently we're not allowing 'Broadcast' push to all users for :app partitioned sources
      return if self.partition.to_sym == :app

      users = [self.user_id]
      User.ping({'user_id' => users, 'sources' => [self.name]})
    end

    private
    def poll_interval_key
      "source:#{self.name}:poll_interval"
    end

    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end

  end
end