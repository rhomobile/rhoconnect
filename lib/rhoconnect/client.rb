module Rhoconnect  
  class InvalidSourceNameError < RuntimeError; end
  
  class Client < StoreOrm
    field :device_type,       :string
    field :device_push_type,  :string
    field :device_pin,        :string
    field :device_port,       :string
    field :device_app_id,       :string
    field :device_app_version,       :string
    field :phone_id,          :string
    field :user_id,           :string
    field :last_sync,         :datetime
    field :app_id,            :string
    attr_accessor :source_name
    validates_presence_of :app_id, :user_id
    
    include Document
    include LockOps

    define_valid_doctypes([:cd, 
                :cd_size, 
                :page, 
                :delete_page, 
                :create_links,
                :create_links_page,
                :metadata_page,
                :total_count_page,
                :page_token,
                :schema_sha1, 
                :schema_page,
                :metadata_sha1,
                :metadata_page,
                :search,
                :search_token,
                :search_page,
                :search_errors,
                :create_errors,
                :create_errors_page,
                :update_errors,
                :update_errors_page,
                :update_rollback,
                :update_rollback_page,
                :delete_errors,
                :delete_errors_page])
    
    def self.create(fields,params={})
      fields[:id] ||= get_random_identifier
      res = super(fields,params)
      user = User.load(fields[:user_id])
      user.clients << res.id
      if Rhoconnect.stats
        Rhoconnect::Stats::Record.set('clients') { Store.incr('client:count') }
      else
        Store.incr('client:count')
      end
      res
    end
    
    def self.load(id,params)
      validate_attributes(params)
      super(id,params)
    end
    
    def app
      @app ||= App.load(app_id)
    end
    
    def doc_suffix(doctype)
      doctype = doctype.to_s
      if self.source_name 
        "#{self.user_id}:#{self.id}:#{self.source_name}:#{doctype}"
      else
        raise InvalidSourceNameError.new('Invalid Source Name For Client')   
      end          
    end
    
    def store_index(doctype)
      source = Source.load(self.source_name,{:app_id => app_id,:user_id => self.user_id})
      index = compute_store_index(doctype, source, user_id)
    end

    def delete
      flush_all_documents
      if Rhoconnect.stats
        Rhoconnect::Stats::Record.set('clients') { Store.decr('client:count') }
      else
        Store.decr('client:count')
      end
      super
    end

    def flush_all_documents
      app.sources.each do |sourcename|
        flush_source_documents(sourcename)
      end  
    end

    def flush_source_documents(source_name)
      self.class.valid_doctypes.each do |docname, doctype|
        flush_source_data(docname, source_name)
      end
    end

    def flush_source_data(doctype, from_source)
      verify_doctype(doctype)
      self.source_name=from_source
      docnamestr = docname('') + doctype.to_s
      Store.flush_data(docnamestr)
    end

    def switch_user(new_user_id)
      loaded_source = self.source_name
      flush_all_documents
      User.load(self.user_id).clients.delete(self.id)
      User.load(new_user_id).clients << self.id
      self.user_id = new_user_id
      self.source_name = loaded_source
    end
    
    def update_clientdoc(sources)
      # TODO: We need to store schema info and data info in bulk data
      # source masterdoc and source schema might have changed!
      sources.each do |source|
        s = Source.load(source,{:app_id => app_id,:user_id => user_id})
        self.source_name = source
        unless s.sync_type.to_sym == :bulk_sync_only
          s.clone(:md_copy,self.docname(:cd))
        end
        self.put_value(:schema_sha1,s.get_value(:schema_sha1))
      end
    end
    
    def update_fields(params)
      [:device_type, :device_push_type,:device_pin,:device_port,:phone_id, :device_app_id, :device_app_version].each do |setting|
        self.send "#{setting}=".to_sym, params[setting].to_s if params[setting]
      end 
    end
    
    private
    
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute source_name') unless params[:source_name]
    end
  end
end
