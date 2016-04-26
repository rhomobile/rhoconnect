require 'resque'
require 'rhoconnect/jobs/bulk_data_job'

module Rhoconnect
  class BulkData < StoreOrm
    field :name, :string
    field :state, :string
    field :app_id, :string
    field :user_id, :string
    field :refresh_time, :integer
    field :dbfile,:string
    list  :sources, :string
    list  :partition_sources, :string
    validates_presence_of :app_id, :user_id, :sources, :partition_sources
    
    def completed?
      if state.to_sym == :completed
        return true
      end
      false
    end
    
    def delete
      sources[0, -1].each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        s.flush_data(:md_copy) if s
      end
      super
    end
    
    def process_sources
      sources[0, -1].each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        if s
          rh = lambda { @model.query(params[:query])}
          model = Rhoconnect::Model::Base.create(s)
          Rhoconnect::Handler::Query::Engine.new(model, rh, {}).run_query
          s.clone(:md, s.docname(:md_copy)) unless s.sync_type.to_sym == :bulk_sync_only
        end
      end
    end
    
    def url
      zippath = dbfile.gsub(Regexp.compile(Regexp.escape(Rhoconnect.data_directory)), "")
      URI.escape(File.join('/data',zippath))
    end
    
    def dbfiles_exist?
      files = [dbfile,dbfile+'.rzip']
      files.each do |file|
        return false unless File.exist?(file)
      end
      true
    end

    def delete_files
      FileUtils.rm Dir.glob(File.join(Rhoconnect.base_directory, "#{self.url}*"))
    end
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        fields[:state] ||= :inprogress
        fields[:sources] ||= []
        fields[:partition_sources] ||= []
        super(fields)
      end
      
      def enqueue(params={})
        Resque.enqueue(BulkDataJob,params)
      end
      
      def get_name(partition,user_id)
        if partition == :user
          File.join(APP_NAME,user_id,user_id)
        else
          File.join(APP_NAME,APP_NAME)
        end
      end
      
      def schema_file
        File.join(File.dirname(__FILE__),'syncdb.schema')
      end
      
      def index_file
        File.join(File.dirname(__FILE__),'syncdb.index.schema')
      end
    end
  end
end

