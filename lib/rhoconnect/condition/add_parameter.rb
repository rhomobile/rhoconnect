module Rhoconnect
  module Condition
    module AddParameter
      def self.extended(base)
        base.include_add_parameter_condition
      end

      def include_add_parameter_condition
        set(:add_parameter) do |*args|
          condition do
          	if args
          		args.each do |argument|
              	params[argument[0]] = argument[1]
            	end
            end
          end
        end
      end
    end
  end
end
