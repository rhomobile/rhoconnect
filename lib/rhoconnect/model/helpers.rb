require 'rhoconnect/model/helpers/find_duplicates_on_update'

module Rhoconnect
	module Model
		module Helpers
			def self.extended(base)
				base.send :include, Rhoconnect::Model::Helpers::FindDuplicatesOnUpdate
			end

			def validators
				@validators ||= {}
			end
		end
	end
end