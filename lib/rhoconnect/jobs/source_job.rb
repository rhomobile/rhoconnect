module Rhoconnect
  class SourceJob
    class << self
      attr_accessor :queue
    end

    def self.perform(job_type,source_id,app_id,user_id,params)
      source = Source.load(source_id,{:app_id => app_id,:user_id => user_id})
      params ||= {}

      case job_type.to_sym
      when :query 
        handler_sync = lambda { @model.query(params[:query])}
        @model = Rhoconnect::Model::Base.create(source)
        source_sync = Rhoconnect::Handler::Query::Engine.new(@model, handler_sync, params)
        source_sync.run_query
      when :cud
        handler_cud = lambda { @model.send params[:operation].to_sym, params["#{params[:operation]}_object".to_sym] }
        @model = Rhoconnect::Model::Base.create(source)
        source_cud = Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], @model, handler_cud, params)
        source_cud.run_cud
      end    
    end
  end
end