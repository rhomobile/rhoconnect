module Rhoconnect
  module Controller
    class SourceAdapterBase < Rhoconnect::Controller::Base
      # create SourceAdapterController class for every source
      def self.register_controller(source_name)
        return if Object.const_defined?("#{source_name}Controller")
        # klass will be added automatically to the URL map
        klass = Object.const_set("#{source_name}Controller", Class.new(Rhoconnect::Controller::SourceAdapterBase))
        klass.register Rhoconnect::EndPoint
        klass.register Rhoconnect::Handler::Sync
      end
    end
  end
end