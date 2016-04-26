module Rhoconnect
  module Condition
    module VerifySuccess
      def self.extended(base)
        base.include_verify_success_condition
      end

    	def include_verify_success_condition
    	  set(:verify_success) do |value|
    	  	condition do
    	  	  if value
    	  	  	success?
    	  	  end
    	  	end
    	  end
    	end
    end
  end
end