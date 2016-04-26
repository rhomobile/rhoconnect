module Rhoconnect
  class ApiToken < StoreOrm
    field :value,:string
    field :user_id,:string
    validates_presence_of :user_id

    def self.create(fields)
      fields[:value] = fields[:value] || get_random_identifier
      fields[:id] = fields[:value]
      super(fields)
    end

    def user
      User.load(self.user_id)
    end
  end
end
