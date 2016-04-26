require 'zip'
require 'zlib'

module Rhoconnect
  module BulkDataJob
    @queue = :bulk_data

    def self.perform(params)
      do_bulk_job(params) do |bulk_data|
        timer = start_timer('starting bulk data process')
        bulk_data.process_sources
        timer = lap_timer('process_sources',timer)
        ts = Time.now.to_i.to_s
        create_sqlite_data_file(bulk_data,ts)
        timer = lap_timer('create_sqlite_data_file',timer)
        log "bulk_data.dbfile:  #{bulk_data.dbfile}"
        log "finished bulk data process"
      end
    end

    def self.after_perform_x(*args)
      log "BulkDataJob.after_perform_x hook called ..."
      params = args[0] # 1st parameter is bulk data
      do_bulk_job(params) do |bulk_data|
        bulk_data.state = :completed
        bulk_data.refresh_time = Time.now.to_i + Rhoconnect.bulk_sync_poll_interval
      end
      log "BulkDataJob.after_perform_x hook set data state to complete."
    end

    def self.do_bulk_job(params)
      bulk_data = nil
      begin
        bulk_data = BulkData.load(params["data_name"]) if BulkData.is_exist?(params["data_name"])
        if bulk_data
          yield bulk_data
        else
          raise Exception.new("No bulk data found for #{params["data_name"]}")
        end
      rescue Exception => e
        bulk_data.delete if bulk_data
        log "Bulk data job raised: #{e.message}"
        log e.backtrace.join("\n")
        raise e
      end
    end

    def self.import_data_to_object_values(db,source,is_selected=true)
      data = {}
      data = source.get_data(:md) if is_selected
      counter = {}
      db.transaction do |database|
        database.prepare("insert into object_values
          (source_id,attrib,object,value) values (?,?,?,?)") do |stmt|
          data.each do |object_id,object|
            object.each do |attrib,value|
              counter[attrib] = counter[attrib] ? counter[attrib] + 1 : 1
              stmt.execute(source.source_id.to_i,attrib,object_id,value)
            end
          end
        end
      end
      counter
    end

    # Loads data into fixed schema table based on source settings
    def self.import_data_to_fixed_schema(db,source,is_selected=true)
      data = {}
      data = source.get_data(:md) if is_selected
      # counter = {}
      columns,qm = [],[]
      create_table = ["\"object\" varchar(255) PRIMARY KEY"]
      schema = JSON.parse(source.schema)

      db.transaction do |database|
        # Create a table with columns specified by 'property' array in settings
        schema['property'].each do |key,value|
          create_table << "\"#{key}\" varchar default NULL"
          columns << key
          qm << '?'
        end
        database.execute("CREATE TABLE #{source.name}(#{create_table.join(",")} );")

        database.prepare("insert into #{source.name} (object,#{columns.join(',')}) values (?,#{qm.join(',')})") do |stmt|
          data.each do |obj,row|
            args = [obj]
            columns.each { |col| args << row[col] }
            # The * is used to expand an array into individual arguments for 'execute' method.
            # JRuby (1.6.0) won't work without asterisk, but other rubies doing well!
            stmt.execute(*args)
          end
        end

        # Create indexes for specified columns in settings 'index'
        schema['index'].each do |key,value|
          val2 = ""
          value.split(',').each do |col|
            val2 += ',' if val2.length > 0
            val2 += "\"#{col}\""
          end

          database.execute("CREATE INDEX #{key} on #{source.name} (#{val2});")
        end if schema['index']

        # Create unique indexes for specified columns in settings 'unique_index'
        schema['unique_index'].each do |key,value|
          val2 = ""
          value.split(',').each do |col|
            val2 += ',' if val2.length > 0
            val2 += "\"#{col}\""
          end

          database.execute("CREATE UNIQUE INDEX #{key} on #{source.name} (#{val2});")
        end if schema['unique_index']
      end

      return {}
    end

    def self.refs_to_s(refs)
      str = ''
      refs.sort.each do |name,value|
        str << "#{name},#{value},"
      end
      str[0..-2]
    end

    # #2354: Bulk sync not updating sources table
    # last_inserted_size +
    # last_deleted_size
    # backend_refresh_time +
    def self.populate_sources_table(db,sources_refs)
      db.transaction do |database|
        database.prepare("insert into sources
          (source_id,name,sync_priority,partition,sync_type,source_attribs,metadata,schema,blob_attribs,associations,last_inserted_size,backend_refresh_time)
          values (?,?,?,?,?,?,?,?,?,?,?,?)") do |stmt|
          sources_refs.each do |source_name,ref|
            s = ref[:source]
            # skipped sources should be marked with sync type :none
            sync_type = ref[:skip_source] ? 'none' : s.sync_type.to_s
            stmt.execute(s.source_id,s.name,s.priority,s.partition_type.to_s,
              sync_type,refs_to_s(ref[:refs]),s.get_value(:metadata),s.schema,s.blob_attribs,s.has_many,s.get_value(:md_size).to_i,s.read_state.refresh_time)
          end
        end
      end
    end

    def self.create_sqlite_data_file(bulk_data,ts)
      sources_refs = {}
      schema,index,bulk_data.dbfile = get_file_args(bulk_data.name,ts)
      FileUtils.mkdir_p(File.dirname(bulk_data.dbfile))
      # TODO: remove old bulk files!
      # FileUtils.rm Dir.glob(File.join(Rhoconnect.data_directory, "#{bulk_data.name}*"))

      db = DBAdapter.instance.get_connection(bulk_data.dbfile)
      db.execute_batch(File.open(schema,'r').read)

      src_counter = 1
      selected_sources = {}
      bulk_data.sources[0, -1].each do |source|
        selected_sources[source] = true
      end
      bulk_data.partition_sources[0, -1].each do |source_name|
        timer = start_timer("start importing sqlite data for #{source_name}")
        source = Source.load(source_name,{:app_id => bulk_data.app_id,
          :user_id => bulk_data.user_id})
        source.source_id = src_counter
        src_counter += 1
        source_attrib_refs = nil
        is_selected_source = selected_sources.has_key?(source_name)
        if source.schema
          source_attrib_refs = import_data_to_fixed_schema(db,source,is_selected_source)
        else
          source_attrib_refs = import_data_to_object_values(db,source,is_selected_source)
        end
        sources_refs[source_name] =
          {:source => source, :refs => source_attrib_refs, :skip_source => !is_selected_source}
        lap_timer("finished importing sqlite data for #{source_name}",timer)
      end
      populate_sources_table(db,sources_refs)

      db.execute_batch(File.open(index,'r').read)
      db.execute_batch("VACUUM;");
      db.close

      compress("#{bulk_data.dbfile}.rzip",bulk_data.dbfile)
      gzip_compress("#{bulk_data.dbfile}.gzip",bulk_data.dbfile)
    end

    def self.get_file_args(bulk_data_name,ts)
      schema = BulkData.schema_file
      index = BulkData.index_file
      dbfile = File.join(Rhoconnect.data_directory,bulk_data_name+'_'+ts+'.data')
      [schema,index,dbfile]
    end

    def self.compress(archive,file)
      Zip::File.open(archive, 'w') do |zipfile|
        zipfile.add(URI.escape(File.basename(file)),file)
      end
    end

    def self.gzip_compress(archive,file)
      data = File.new(file, "rb")
      File.open(archive, 'wb') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write data.read
        gz.close
      end
      data.close
    end

  end
end