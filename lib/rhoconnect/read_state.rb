module Rhoconnect  
  class ReadState < StoreOrm
    field :refresh_time, :integer
    field :prev_refresh_time, :integer
    field :retry_counter, :integer
  
    def self.create(fields)
      fields[:id] = get_id(fields)
      fields.delete(:app_id)
      fields.delete(:user_id)
      fields.delete(:source_name)
      fields[:refresh_time] ||= Time.now.to_i
      fields[:prev_refresh_time] ||= Time.now.to_i
      fields[:retry_counter] ||= 0
      super(fields,{})
    end
  
    def self.load(params)
      super(get_id(params),{})
    end
    
    def self.delete(app_id)
      Store.flush_data("#{class_prefix(self)}:#{app_id}:*")
    end
    
    def self.delete_user(params)
      Store.flush_data("#{class_prefix(self)}:#{params[:app_id]}:#{params[:user_id]}:#{params[:source_name]}:*")
    end

    private
    def self.get_id(params)
      "#{params[:app_id]}:#{params[:user_id]}:#{params[:source_name]}"
    end
  end
end