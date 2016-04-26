require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Condition
    module LoginRequired
      def self.extended(base)
        base.include_login_required_condition
      end

      def include_login_required_condition
        set(:login_required) do |value|
          #puts "lgin kls is #{self.to_s}"
          condition do
            if value
              throw :halt, [401, {'Content-Type' => 'text/plain'}, "Not authenticated"] if @env[Rhoconnect::CURRENT_USER].nil?
            end
          end
        end
      end
    end
  end
end