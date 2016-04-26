module Rhoconnect
  class Stats
    class Record
      class << self
      
        # Add a value to a metric.  If zset already has a member, 
        # update the existing member with an incremented value by default.
        # Also supports updating the value with a block (useful for averages)
        def set(metric, value = 0)
          start = (Time.now.to_i / resolution(metric)) * resolution(metric)
          current, current_score = 0, start
          Store.lock(key(metric)) do
            range = Store.zrevrange(key(metric), 0, 0)
            if !range.empty?
              member = range[0]
              m_current = member.split(':')[0]
              m_current_score = Store.zscore(key(metric), member).to_i
              if m_current_score > (start - resolution(metric))
                Store.zrem(key(metric), member)
                current, current_score = m_current, m_current_score
              end
            end
            value = block_given? ? yield(current, value) : value 
            Store.zadd(key(metric), current_score, "#{value}:#{start}")
            Store.zremrangebyscore(key(metric), 0, start - record_size(metric))
          end
        end
      
        def add(metric, value = 1)
          set(metric,value) { |current,value| current.to_i + value } 
        end
      
        # Saves the accumulated average for a resolution in a metric
        def save_average(metric, value)
          set(metric,value) do |current,value| 
            sum = value
            if current.is_a?(String)
              current,sum = current.split(',')
              current = current.to_f
              sum = sum.to_f+value
            end
            "#{current + 1},#{sum}"
          end  
        end
      
        def update(metric)
          if Rhoconnect.stats
            start = Time.now.to_f
            # perform the operations
            yield
            finish = Time.now.to_f
            save_average(metric, finish - start)
          else
            yield
          end
        end
      
        def keys(glob='*')
          Store.keys(key(glob)).collect {|c| c[5..-1]}
        end
      
        def reset(metric)
          Store.flush_data(key(metric))
        end
      
        def reset_all
          Store.flush_data('stat:*')
        end
      
        # Returns simple string metric
        def get_value(metric)
          Store.get_value(key(metric))
        end
      
        # Sets a string metric
        def set_value(metric, value)
          Store.set_value(key(metric), value)
        end
    
        # Returns the metric data, uses array indexing
        def range(metric, start, finish = -1)
          Store.zrange(key(metric), start, finish)
        end
      
        # Returns the resolution for a given metric, default 60 seconds
        def resolution(metric)
          resolution = STATS_RECORD_RESOLUTION rescue nil
          resolution || 60 #=> 1 minute aggregate
        end
      
        # Returns the # of records to save for a given metric
        def record_size(metric)
          size = STATS_RECORD_SIZE rescue nil
          size || 60 * 24 * 31 #=> 44640 minutes
        end
      
        # Returns redis object type for a record
        def rtype(metric)
          Store.doc_type(key(metric))
        end
      
        def key(metric)
          "stat:#{metric}"
        end
      end
    end
  end
end