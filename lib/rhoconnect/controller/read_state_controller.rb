module Rhoconnect
  module Controller  
    class ReadStateController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint
      
      put "/users/:user_name/sources/:source_name", \
                  :deprecated_route => {:verb => :post, :url => ['/api/set_refresh_time', '/api/source/set_refresh_time']} do
        source = Source.load(params[:source_name],
          {:app_id => APP_NAME, :user_id => params[:user_name]})
        source.poll_interval = params[:poll_interval] if params[:poll_interval]
        params[:refresh_time] ||= 0
        source.read_state.refresh_time = Time.now.to_i + params[:refresh_time].to_i
        ''
      end
    end
  end
end