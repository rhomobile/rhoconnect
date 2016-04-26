module Rhoconnect
  module Handler
    module Helpers
      module BulkData
        def do_bulk_data(partition, client, sources = nil)
          raise ArgumentError.new(UNKNOWN_CLIENT) unless client
          name = Rhoconnect::BulkData.get_name(partition,client.user_id)
          data = Rhoconnect::BulkData.load(name)

          partition_sources = client.app.partition_sources(partition,client.user_id)	
          sources ||= partition_sources
          return {:result => :nop} if sources.length <= 0

          do_bd_sync = data.nil?
          do_bd_sync = (data.completed? and 
              (data.refresh_time <= Time.now.to_i or !data.dbfiles_exist?)) unless do_bd_sync

          if do_bd_sync  
            data.delete if data
            data = Rhoconnect::BulkData.create(:name => name,
              :app_id => client.app_id,
              :user_id => client.user_id,
              :partition_sources => partition_sources,
              :sources => sources,
              :refresh_time => Time.now.to_i + Rhoconnect.bulk_sync_poll_interval)
            Rhoconnect::BulkData.enqueue("data_name" => name)
          end
          
          if data and data.completed? and data.dbfiles_exist?
            client.update_clientdoc(sources)
            sources.each do |src|
              s = Source.load(src, {:user_id => client.user_id, :app_id => client.app_id})
              errors = {}
              s.lock(:errors) do
                errors = s.get_data(:errors)
              end
              unless errors.empty?
                # FIXME: :result => :bulk_sync_error, :errors => "#{errors}"
                log "Bulk sync errors are found in #{src}: #{errors}"
                # Delete all related bulk files
                data.delete_files
                return {:result => :url, :url => ''}
              end
            end
            {:result => :url, :url => data.url}
          elsif data
            {:result => :wait}
          end
        end
      end
    end
  end
end