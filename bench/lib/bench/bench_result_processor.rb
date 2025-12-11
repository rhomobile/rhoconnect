#!/usr/bin/ruby
require 'rubygems'

module Bench
  def self.gem_installed?(gem_name)
    (Gem::Specification.respond_to?(:find_by_name) ?
     Gem::Specification.find_by_name(gem_name) : Gem.source_index.find_name(gem_name).last) != nil
  rescue Exception => e
    false
  end

  module PostProcessing
    @plugins = ['RhoSpreadSheet','RhoGruff']
    
    
    def self.execute(res_dir)
      return unless res_dir
      
      puts ""
      puts "Starting Benchmark Post-Processing ..."
      puts ""
      
      @plugins.each do |plugin|
        plugin_class = eval(plugin)
        available = plugin_class.has?
        if available
          available = plugin_class.load_myself
        end
        
        # print the message
        if not available
          puts ""
          plugin_class.what_is_needed?
          puts ""
          next
        end
        
        plugin_instance = plugin_class.new
        plugin_instance.process res_dir
      end
    end
    
    # this post-processor creates EXCEL spreadsheets
    class RhoSpreadSheet
      def self.has?
        Bench::gem_installed?('spreadsheet')
      end  
      
      def self.what_is_needed?
        puts "In order to run SpreadSheet post-processor - you need to have SpreadSheet gem installed"
        puts "Install it by using : '[sudo] gem install spreadsheet'"
      end 
    
      def self.load_myself
        require 'yaml'
        require 'spreadsheet'
        true
      end
          
      def process(res_dir)
        current_dir = Dir.pwd
        begin
          puts "Starting SpreadSheet post-processor..."
          # 1) Create images dir
          Dir.chdir res_dir
          @results_dir = Dir.pwd
          output_dir = Bench.create_subdir 'spreadsheet'
          Dir.chdir output_dir
          @output_dir = Dir.pwd
          
          _load_meta_hash
          _init
          _process_res_files
          _write
          Dir.chdir current_dir
        rescue Exception => e
          Dir.chdir current_dir
          raise e
        end 
      end
      
      def _load_meta_hash
        # load meta.yaml
        @meta_hash = YAML.load_file(File.join(@results_dir,'raw_data','meta.yml')) if File.exist?(File.join(@results_dir,'raw_data','meta.yml'))
        if @meta_hash.nil?
          raise "SpreadSheet Result Processor: No valid meta.yml file is found in the result directory - Skipping ..."
        end

        @metrics = @meta_hash[:metrics]
        if @metrics.nil?
          raise "SpreadSheet Result Processor: No valid metrics are found in the result directory - Skipping ..."
        end

        if @meta_hash[:x_keys].nil?
          raise "SpreadSheet Result Processor: No valid x_keys are found in the result directory - Skipping ..."
        end
        @x_keys = @meta_hash[:x_keys].keys
        @x_keys = @x_keys.sort_by(&Bench.sort_natural_order)
      end
      
      def _init
        # initialize graphs for each metric
        # row 0 - payload labels
        # col 0 - X keys  
        @title = @meta_hash[:label]
        @book = Spreadsheet::Workbook.new(@title)
        @sheets = {}
        axis_format = Spreadsheet::Format.new :color => :blue,
                                             :weight => :bold,
                                             :size => 18
        @metrics.each do |name,index|
          sheet = @book.create_worksheet({:name => "#{name} (#{@title})"})
          @sheets[index] = sheet
          sheet.column(0).default_format = axis_format
          sheet.row(0).default_format = axis_format             
          @meta_hash[:x_keys].each do |key,key_index|
            sheet[key_index + 1, 0] = "#{key}"
          end
        end 
      end
      
      def _process_res_files
        # load all result files
        res_files = Dir.entries(File.join(@results_dir,'raw_data')).collect { |entry| entry if entry =~ /bench.*result/ }
        res_files.compact!
        res_files = res_files.sort_by(&Bench.sort_natural_order)
        
        res_files.each_with_index do |entry, entry_index|
          begin
            res_hash = YAML.load_file(File.join(@results_dir,'raw_data',entry))
            next if res_hash.nil? or res_hash.empty?

            marker = entry.split('.').last.to_s
            
            @sheets.each do |index,sheet|
              sheet[0, entry_index + 1] = "#{marker}"                        
            end

            g_data = Array.new(@metrics.size) { Array.new }
            @x_keys.each do |x_key|
              row_idx = @meta_hash[:x_keys][x_key] + 1
              results = res_hash[x_key]
              results ||= Array.new(@metrics.size, 0.0)
              results.each_with_index do |res, index|
                col_idx = entry_index + 1
                @sheets[index][row_idx,col_idx] = ("%0.4f" % res).to_f
              end
            end
          rescue Exception => e
            raise "SpreadSheet processing resulted in Error : #{e.message} " + e.backtrace.join("\n")
          end
        end 
      end
      
      def _write
        image_fname = File.join(@output_dir,"bench_results.xls")
        puts "Spreadsheet processor: writing #{image_fname}"
        @book.write image_fname
      end
    end
    
    # this post-processor creates PNG graph files
    class RhoGruff
      def self.has?
        Bench::gem_installed?('gruff')
      end 
      
      def self.what_is_needed?
        puts "In order to run Gruff post-processor - you need to have Gruff gem installed"
        puts "Install it by using : '[sudo] gem install gruff'"
        puts "You may also need to install additional components - please check Gruff documentation for details"
      end  
    
      def self.load_myself
        res = true
        begin
          require 'yaml'
          require 'gruff'
        rescue Exception => e
          puts " Can not run Gruff post-processor : #{e.message}"
          res = false
        end
        res
      end
          
      def process(res_dir)
        current_dir = Dir.pwd
        begin
          puts "Starting Gruff post-processor..."
          # 1) Create images dir
          Dir.chdir res_dir
          @results_dir = Dir.pwd
          output_dir = Bench.create_subdir 'images'
          Dir.chdir output_dir
          @output_dir = Dir.pwd
          
          _load_meta_hash
          _init_graphs
          _process_res_files
          _write_graphs
          Dir.chdir current_dir
        rescue Exception => e
          Dir.chdir current_dir
          raise e
        end 
      end
      
      def _load_meta_hash
        # load meta.yaml
        @meta_hash = YAML.load_file(File.join(@results_dir,'raw_data','meta.yml')) if File.exist?(File.join(@results_dir,'raw_data','meta.yml'))
        if @meta_hash.nil?
          raise "Gruff Result Processor: No valid meta.yml file is found in the result directory - Skipping ..."
        end

        @metrics = @meta_hash[:metrics]
        if @metrics.nil?
          raise "Gruff Result Processor: No valid metrics are found in the result directory - Skipping ..."
        end

        if @meta_hash[:x_keys].nil?
          raise "Gruff Result Processor: No valid x_keys are found in the result directory - Skipping ..."
        end
        @x_keys = @meta_hash[:x_keys].keys
        @x_keys = @x_keys.sort_by(&Bench.sort_natural_order)
      end
      
      def _init_graphs
        # initialize graphs for each metric
        @graphs = {}
        @title = @meta_hash[:label]
        @metrics.each do |name,index|
          g = Gruff::Line.new
          g.title = "#{@title} (#{name})"
          g.labels = @meta_hash[:x_keys].invert
          @graphs[index] = g
        end 
      end
      
      def _process_res_files
        # load all result files
        res_files = Dir.entries(File.join(@results_dir,'raw_data')).collect { |entry| entry if entry =~ /bench.*result/ }
        res_files.compact!
        res_files = res_files.sort_by(&Bench.sort_natural_order)
        
        # we can only create 7 unique lines
        # per graph
        for entry in res_files.last(7) do
          begin
            res_hash = YAML.load_file(File.join(@results_dir,'raw_data',entry))
            next if res_hash.nil? or res_hash.empty?

            marker = entry.split('.').last.to_s

            g_data = Array.new(@metrics.size) { Array.new }
            @x_keys.each do |x_key|
              results = res_hash[x_key]
              results ||= Array.new(@metrics.size, 0.0)
              results.each_with_index do |res, index|
                g_data[index] << ("%0.4f" % res).to_f
              end
            end

            @graphs.each do |index, graph|
              graph.data("#{marker}", g_data[index])
            end
          rescue Exception => e
            raise "Gruff processing resulted in Error : " + e.backtrace.join("\n")
          end
        end 
      end
      
      def _write_graphs
        # write out resulting graphs
        @metrics.each do |name, index|
          image_fname = File.join(@output_dir,"#{name}.png")
          puts "Gruff processor: writing #{image_fname}"
          @graphs[index].write image_fname
        end 
      end
    end
  end
end

