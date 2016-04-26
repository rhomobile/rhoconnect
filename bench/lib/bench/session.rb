module Bench
  class Session
    include Logging
    include Timer
    attr_accessor :cookies, :last_result, :results, :thread_id, :iteration, :client_id
    
    def initialize(thread_id,iteration)
      @cookies = {}
      @results = {}
      @thread_id,@iteration = thread_id,iteration
    end
      
    def post(marker,url,headers={})
      @body = yield if block_given?
      _request(marker,:_post,url,headers)
    end
    
    def get(marker,url,headers={})
      params = yield if block_given?
      url_params = url.clone
      url_params << "?" + _url_params(params) if params
      _request(marker,:_get,url_params,headers)          
    end
    
    def delete(marker,url,headers={})
      _request(marker,:_delete,url,headers)          
    end
    
    protected
    def _request(marker,verb,url,headers)
      result = Result.new(marker,verb,url,@thread_id,@iteration)
      @results[result.marker] ||= []
      @results[result.marker] << result
      begin
        result.time = time do
          headers.merge!(:cookies => @cookies)
          result.last_response = send(verb,url,headers)
          @last_result = result
        end
        if request_logging
          bench_log "#{log_prefix} #{verb.to_s.upcase.gsub(/_/,'')} #{url} #{@last_result.code} #{result.time}"
        end    
      rescue RestClient::Exception => e
        result.error = e
        bench_log "#{log_prefix} #{verb.to_s.upcase.gsub(/_/,'')} #{url}"      
        bench_log "#{log_prefix} #{e.http_code.to_s} #{e.message}\n"
        raise e
      end
      @last_result.cookies['rhoconnect_session'] = 
        CGI.escape(@last_result.cookies['rhoconnect_session']) if @last_result.cookies['rhoconnect_session']
      @cookies = @cookies.merge(@last_result.cookies)
      @last_result
    end
    
    def _get(url,headers)
      #bench_log "GET #{url}"
      RestClient.get(url, headers)
    end
    
    def _post(url,headers)
      #bench_log "POST #{url}"
      RestClient.post(url, @body, headers)
    end
    
    def _delete(url,headers)
      RestClient.delete(url, headers)
    end
    
    def _url_params(params)
      elements = []
      params.each do |key,value|
        elements << "#{key}=#{value}"
      end
      elements.join('&')
    end
  end
end