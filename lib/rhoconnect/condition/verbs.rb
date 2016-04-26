module Rhoconnect
  module Condition
    module Verbs
      def self.extended(base)
      	base.include_verbs_condition
      end

      def include_verbs_condition
        set(:verbs) do |*verbs|
          condition do
            verbs.any?{|v| v == request.request_method }
          end
        end
      end
    end
  end
end
