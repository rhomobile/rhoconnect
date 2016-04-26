require 'timeout'
require 'open-uri'
require 'securerandom'

module Rhoconnect
  class NodeChannel
    class << self
      attr_accessor :redis,:redis2,:message_thread
      @message_thread = nil
    end

    RESULT_HASH          = {}
    PUBSUB_IDENTIFIER    = "#{$$}-#{SecureRandom.hex}"
    PUB_CHANNEL          = "#{PUBSUB_IDENTIFIER}-RedisSUB" # pub channel must link to redis sub channel
    SUB_CHANNEL          = "#{PUBSUB_IDENTIFIER}-RedisPUB" # sub channel must link to redis pub channel
    @message_thread,@redis_subscriber,@redis_publisher = nil

    class << self
      attr_accessor :thrd, :register_semaphore, :register_condition, :timeout

      def redis_subscriber
        url = Rhoconnect.redis.is_a?(Array) ? Rhoconnect.redis[0] : Rhoconnect.redis
        db_inst = RedisImpl.new
        db_inst.create(url)
        @redis_subscriber ||= db_inst.db
      end

      def redis_publisher
        url = Rhoconnect.redis.is_a?(Array) ? Rhoconnect.redis[0] : Rhoconnect.redis
        db_inst = RedisImpl.new
        db_inst.create(url)
        @redis_publisher ||= db_inst.db
      end

      def exit_node
        NodeChannel.redis_publisher.publish(PUB_CHANNEL,{:route => 'deregister'}.to_json)
      end

      def bootstrap(timeout)
        @register_semaphore ||= Mutex.new
        @register_condition ||= ConditionVariable.new
        # Run in the main thread, we setup node thread and wait for it to
        # finish bootstrapping before main thread can continue
        if @message_thread
          @message_thread.join
          @message_thread = nil
        end
        @register_semaphore.synchronize do
          @message_thread = Thread.new{check_channel}
          @register_condition.wait(@register_semaphore)
        end
        @timeout = timeout
      end

      def publish_channel_and_wait(msg,curr_model)
        unique_id = get_random_identifier
        msg.merge!(:request_id => unique_id)
        RESULT_HASH[unique_id] = {}
        RESULT_HASH[unique_id][:status] = 'waiting'
        publish_channel(PUB_CHANNEL,msg,unique_id,curr_model)
      end

      def check_channel
        NodeChannel.redis_subscriber.subscribe(SUB_CHANNEL) do |on|
          on.message do |channel,msg|
            m = JSON.parse(msg)
            if m['exit'] == true
              NodeChannel.redis_subscriber.unsubscribe
            end
            route_message(m)
          end
        end
      end

      def publish_channel(channel,msg,unique_id = nil,curr_model = nil)
        result = {}
        num_clients = NodeChannel.redis_publisher.publish(channel,msg.to_json)
        if num_clients >= 1
          result = NodeChannel.wait_for_result(unique_id,curr_model) if unique_id
        else
          log "ERROR: Cannot communicate with Node.js process."
          if Rhoconnect.restart_node_on_error
            t = Thread.new do
              # Shutdown our ruby subscription by issuing redis channel instruction
              NodeChannel.redis_subscriber.publish(SUB_CHANNEL,{'exit' => true}.to_json)
            end
            t.join
            Rhoconnect.start_nodejs_channels(force: true)
          end
        end
        result
      end

      def wait_for_result(key,curr_model)
        begin
          Timeout::timeout(@timeout) do
            while(RESULT_HASH[key][:status] == 'waiting') do
              if RESULT_HASH[key][:pending_js_requests] and result_id = RESULT_HASH[key][:pending_js_requests][0]
                #do some logic and return data with memory
                data = RESULT_HASH[key][result_id][:process_request]
                msg_result = process_message(curr_model,data)
                RESULT_HASH[key][result_id][:process_result]  = msg_result
                RESULT_HASH[key][:pending_js_requests] = RESULT_HASH[key][:pending_js_requests].drop(1)
                if RESULT_HASH[key][:pending_js_requests].length == 0 and not RESULT_HASH[key][:result].nil?
                  RESULT_HASH[key][:status] = 'done'
                end
                publish_channel(PUB_CHANNEL,msg_result)
              end
              Thread.pass
            end
          end
        rescue Exception=>e
          RESULT_HASH[key][:status] = 'broken'
          RESULT_HASH[key][:result] = "exception #{e.message}\n#{e.backtrace}"
          log "Timeout on wait, setting JavaScript result state to broken: #{e.message}"
          log e.backtrace.join("\n")
        end
        #request waiting either timed out or returned response
        res = {}
        if RESULT_HASH[key][:status] == 'broken' or  RESULT_HASH[key][:status] == 'waiting'
          res = RESULT_HASH.delete(key)
        elsif RESULT_HASH[key] and RESULT_HASH[key][:result].is_a?(Hash) and RESULT_HASH[key][:result]['error_type']
          include Rhoconnect::Model
          res = RESULT_HASH.delete(key)[:result]
          klass = res['error_type']
          exception = nil

          if klass and const_defined?(klass)
            exception = const_get(klass).new(res['message'])
          else
            exception = Exception.new(res['message'])
          end
          exception.set_backtrace(res['stacktrace'].split("\n"))
          raise exception
        else
          res = RESULT_HASH.delete(key)
        end
        res[:result]
      end

      def route_message(msg)
        case msg['route']
        when 'request'
          result_id = get_random_identifier
          RESULT_HASH[msg['request_id']][:pending_js_requests] ||= []
          RESULT_HASH[msg['request_id']][:pending_js_requests] << result_id
          RESULT_HASH[msg['request_id']][result_id] = {}
          RESULT_HASH[msg['request_id']][result_id][:process_result]  = 'waiting'
          RESULT_HASH[msg['request_id']][result_id][:process_request] = msg
        when 'response'
          return if RESULT_HASH[msg['request_id']] == nil
          if msg['error'] and msg['error'].size > 1
            RESULT_HASH[msg['request_id']][:result] = msg['error']
            RESULT_HASH[msg['request_id']][:status] = 'done'
          else
            RESULT_HASH[msg['request_id']][:result] = msg["result"]
            pending_js_requests = RESULT_HASH[msg['request_id']][:pending_js_requests]
            if not pending_js_requests or pending_js_requests.length == 0
              RESULT_HASH[msg['request_id']][:status] = 'done'
            end
          end
        when 'register'
          @register_semaphore.synchronize do
            begin
              register_routes(msg)
            rescue Exception => e
              log "Error registering JavaScript routes: #{e.inspect}"
              log e.backtrace.join("\n")
              raise e
            ensure
              @register_condition.signal
            end
          end
        end
      end

      def process_message(curr_model,data)
        klass = curr_model
        klass = Object.const_get(data['kls']) if data['kls']
        if klass.respond_to?(data['function'].to_sym)
          if data['args'] and data['args'].size > 0
            if(data['function'] == 'stash_result')
              klass.send('result=',data['args'])
              res = klass.send(data['function'])
            else
              res = klass.send(data['function'],*data['args'])
            end
          else
            res = klass.send(data['function'])
            res
          end
        else
          raise Exception.new("Method #{data['function']} not found in model #{curr_model.class.name.to_s}.")
        end

        unless res.is_a?(String) or res.is_a?(TrueClass) or res.is_a?(FalseClass) or res.nil?
          res = res.to_hash
        end
        {:result=>res,:callback=>data['callback'],:request_id=>data['request_id'],:route=>'response'}
      end

      def register_routes(hsh)
        Rhoconnect::Controller::JsBase.register_routes(hsh)
      end
    end
  end
end