module Rhoconnect
  module Controller
    class AppBase < Rhoconnect::Controller::Base
      set_default :admin_required, false
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      def self.inherited(subclass)
        subclass.set_default :admin_required, false
        subclass.set_default :login_required, false
        subclass.set_default :source_required, false
        subclass.set_default :client_required, false
        super
      end

      register Rhoconnect::Handler::Search
      register Rhoconnect::Handler::BulkData

      # main app controller
      def self._rest_name
        "app"
      end

      private
      def self._prefix
        "rc/#{Rhoconnect::API_VERSION}"
      end
    end
  end

  # aliasing Rhoconnect::Base class name to provide backward compatibility
  # TODO: deprecate this class along with application.rb support
  # and remove in 4.1
  class Base < Rhoconnect::Controller::AppBase
    def self.initializer(path=nil)
      require 'rhoconnect/application/init'

      # post deprecation warning !!!
      warning_for_deprecated_application = <<_MIGRATE_TO_NEW_RHOCONNECT

***** WARNING *****
RhoConnect has detected that you're using deprecated Application class.

  Application class support will be removed in RhoConnect 4.1.
  Please, migrate your Application class into ApplicationController.

  For more details, see RhoConnect Migration guidelines at 
  docs.rhomobile.com

_MIGRATE_TO_NEW_RHOCONNECT
      puts warning_for_deprecated_application

      # !!! Add routes here - because otherwise they will be added in all apps
      # even those that has new style Application class
      self.register Rhoconnect::EndPoint

      # Application login
      post "/login", { :rc_handler => :authenticate, :deprecated_route => {:verb => :post, :url => ['/application/clientlogin', '/api/application/clientlogin']},
                      :client_required => false } do
        Application.authenticate(params[:login], params[:password], session)
      end

      # Push service login
      get "/rps_login", :rc_handler => :rps_authenticate, :client_required => false do
        if Application.singleton_methods.map(&:to_sym).include?(:rps_authenticate)
          Application.rps_authenticate(params[:login], params[:password])
        else
          false
        end
      end
    end
  end
end