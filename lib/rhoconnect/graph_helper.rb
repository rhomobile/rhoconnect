module GraphHelper
  
   
   def source_timing(params)
      #name,data,options
      @displayname = params['display_name']
      names = []
    
      names = [params['display_name']]
      @sources = []
      
      names.each do |name|
        s = {}
        data = []
        series = []
        options = { :legend => { :show => true }, :title => name }
        s['name'] = name
        s['data'] = []

        @keys = get_user_count("source:*:#{name}")
        @keyname = params['key'] || @keys.first
        
        xmin = 9999999999999999
        xmax = -1
        ymin = 9999999999999999
        ymax = -1
        
        if @keyname
          method = @keyname.gsub(/source:/,"").gsub(/:.*/,"")
          series << {:showLabel => true, :label => method }
        
          range = get_user_count(nil,@keyname,0,-1)
          thisdata = []
          range.each do |value|
            count = value.split(',')[0]
            value.gsub!(/.*,/,"")
            thisdata << value.split(":").reverse
            thisdata[-1][0] = thisdata[-1][0].to_i * 1000
            thisdata[-1][1] = thisdata[-1][1].to_f
            thisdata[-1][1] /= count.to_f

            ymin = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f < ymin
            ymax = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f > ymax

          end
          data << thisdata
          xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
          xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
      
        
          options[:axes] = {
            :yaxis => { :tickOptions => { :formatString =>'%.3f'}, :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05), :label  => 'Seconds', :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'  }, 
            :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
              :tickOptions => {:formatString => '%m/%d/%y'}}
          }

          s['data'] = data
          options[:series] = series
          options[:cursor] = {:zoom => true, :showTooltip => true} 
          options[:seriesDefaults] = {:pointLabels => { :show=>true }}
          s['options'] = options
        end
        
        @sources << s
      end
    
      erb :jqplot, :layout => false
   end


   def http_timing_key(params)
       @uri   = 'timing/httptiming'
   
       #name,data,options
       @displayname = params['display_name']
     
       @sources = []
       name = key = params['display_name']
       
       s = {}
       data = []
       series = []
       options = { :legend => { :show => false }, :title => name }
       s['name'] = name
 
       xmin = 9999999999999999
       xmax = -1
       ymin = 9999999999999999
       ymax = -1
       
       keys = Rhoconnect::Stats::Record.keys(key)
       
       keys.each_with_index do |k,index|
         method = key.gsub(/http:.*?:/,"")
         #method.gsub!(/:.*/,"") unless name == "*"
         series << {:showLabel => true, :label => method, :showLine => false }

         range = get_user_count(nil,k,0,-1)
         thisdata = []
         range.each do |value|
           count = value.split(',')[0]
           value.gsub!(/.*,/,"")
           thisdata << value.split(":").reverse
           thisdata[-1][0] = thisdata[-1][0].to_i * 1000
           thisdata[-1][1] = thisdata[-1][1].to_f
           thisdata[-1][1] /= count.to_f
         end
         data << thisdata
         xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
         xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
       end
       
       data_normalized,ymin,ymax,days = average_data(data,ymin,ymax)
       #puts "dn is ****************** #{data_normalized}"
       format_str = days ? "%m/%d%y" : "%H"
       label_time = days ? "Days" : "#{data_normalized.first.first[0].year}-#{data_normalized.first.first[0].month}-#{data_normalized.first.first[0].day} (Hours)"
       
       options[:axes] = {
         :yaxis => { :tickOptions => { :formatString =>'%.3f'}, :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05), :label  => 'Seconds', :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'  }, 
         :xaxis => { :autoscale => true, :label  => label_time, :renderer=>'$.jqplot.DateAxisRenderer',
           :tickOptions => {:formatString => format_str}}
       }
       s['data'] = data_normalized
       options[:series] = series
       options[:cursor] = {:zoom => true, :showTooltip => true, :show => true}
       options[:seriesDefaults] = {:pointLabels => { :show=>true },:rendererOptions => {:smooth => true}} 
       s['options'] = options
 
       @sources << s
       
       erb :jqplot, :layout => false
   end
    
  def http_timing(params)
    @uri   = 'timing/httptiming'

    #name,data,options
    
    @displayname  = params['display_name']
    names = ["GET","POST"]
    
    @sources = []
    names = [params['display_name']]

    names.each do |name|
      s = {}
      data = []
      series = []
      options = { :legend => { :show => true, :location => 'ne' }, :title => name }
      s['name'] = name

      name = "*" if name == "ALL"
      keys = get_user_count("http:*:#{name}")
      xmin = 9999999999999999
      xmax = -1
      ymin = 9999999999999999
      ymax = -1
      keys.each_with_index do |key,index|
        method = key.gsub(/http:.*?:/,"")
        method.gsub!(/:.*/,"") unless name == "*"
        series << {:showLabel => true, :label => method}

        range = get_user_count(nil,key,0,-1)
        thisdata = []
        range.each do |value|
          count = value.split(',')[0]
          value.gsub!(/.*,/,"")
          thisdata << value.split(":").reverse
          thisdata[-1][0] = thisdata[-1][0].to_i * 1000
          thisdata[-1][1] = thisdata[-1][1].to_f
          thisdata[-1][1] /= count.to_f

          ymin = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f < ymin
          ymax = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f > ymax

        end
        data << thisdata
        xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
        xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
      end

      options[:axes] = {
        :yaxis => { :tickOptions => { :formatString =>'%.3f'}, :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05), :label  => 'Seconds', :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'  }, 
        :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
          :tickOptions => {:formatString => '%m/%d/%y'}}
      }

      s['data'] = data
      options[:series] = series
      options[:cursor] = {:zoom => true, :showTooltip => true}
      options[:seriesDefaults] = {:rendererOptions => {:smooth => true}} 
      s['options'] = options

      @sources << s
    end
    
    @graph_t = 'http'
    @data = [[[1,2],[3,4],[5,6]]].to_json
    erb :jqplot, :layout => false
  end
  
  def get_http_routes()
    keys = get_user_count("http:*:*")
    keys.each do |k|
      client_id = k.split("/")[4]
      k.gsub!(client_id,"*") if client_id
    end
    keys.uniq
  end
  
  def count_graph(uri,title,name,metric)
  	start = 0
  	finish = -1
  	now = Time.now.to_i
  	format = "%m/%d/%y"

  	thisdata = []
  	series = []
  	series << 
  	options = { :legend => { :show => false },  :title => title }
  	@sources = []

  	s = {}
  	usercount = []

    usercount = get_user_count(nil,metric,start,finish)
    
  	usercount.each do |count|
  	  user,timestamp = count.split(':')
  	  user = user.to_i
  	  timestamp = timestamp.to_i * 1000
  	  thisdata << [timestamp,user]
  	end

  	  options[:axes] = {
  	     :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
  	       :tickOptions => {:formatString => format}},
  	     :yaxis => {:label  => name, :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'}
  	   }

  	options[:cursor] = {:zoom => true, :showTooltip => true} 
  	options[:seriesDefaults] = {:pointLabels => { :show=>true },:rendererOptions => {:smooth => true}} 
  	s['name'] = name
  	s['data'] = [thisdata]
  	s['options'] = options
  	@sources << s
  	erb :jqplot, :layout => false
  end
  
  def get_user_count(name=nil,metric_p=nil,start=nil,finish=nil)
    begin
       if Rhoconnect.stats == true
           names = name
           if names
             Rhoconnect::Stats::Record.keys(names)
           else
             metric = metric_p.strip
             rtype = Rhoconnect::Stats::Record.rtype(metric)
             if rtype == 'zset'
               # returns [] if no results
               Rhoconnect::Stats::Record.range(metric,start,finish)
             elsif rtype == 'string'
               Rhoconnect::Stats::Record.get_value(metric) || ''
             else
               raise ApiException.new(404, "Unknown metric")
             end
           end
       else
         raise ApiException.new(500, "Stats not enabled")
       end
    rescue Exception => e
       usercount = ["0:#{Time.now.to_i}"]
    end
  end
  
  def get_sources(partition_type)
    # app.sources returns reference
    # so we need to make a copy
    # otherwise we will end up modifying the @@sources variable in App 
    sources = App.load(APP_NAME).sources.clone
    if partition_type.nil? or partition_type == 'all'
      sources
    else
      res = []
      sources.each do |name|
        s = Source.load(name,{:app_id => APP_NAME,:user_id => '*'})
        if s.partition_type and s.partition_type == partition_type.to_sym
          res << name 
        end
      end  
      res
    end
  end
  
  def average_data(data,ymin,ymax)
    data_buckets = {}
    data_count   = {}
    data_result  = []
    days         = false
    
    data.each do |d_arr|
      bucket     = Time.at(d_arr.first[0]/1000)
      bucket_key = "#{bucket.year}-#{bucket.month}-#{bucket.day} #{bucket.hour}:0:0"
      if data_buckets.include? bucket_key
        data_buckets[bucket_key] += d_arr.first[1]
        data_count[bucket_key] += 1
      else
        data_buckets[bucket_key] = d_arr.first[1]
        data_count[bucket_key] = 1
      end
      ymin = d_arr.first[1].to_f if d_arr.first[1].to_f < ymin.to_f
      ymax = d_arr.first[1].to_f if d_arr.first[1].to_f > ymax.to_f
    end
    data_buckets.each do |index,value|
      average_val = value/data_count[index]
      data_result << [[Time.at(Time.parse(index).to_i),average_val.round(3)]]
    end
    
    unless data_buckets.size < 2
      start_day = Time.parse(data_buckets.first.first)
      end_day   = Time.parse(data_buckets.last.first)
      days = true if start_day.month != end_day.month and start_day.day != end_day.day
    end
    return data_result,ymin,ymax,days
  end

end