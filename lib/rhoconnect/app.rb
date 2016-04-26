module Rhoconnect
  class App < StoreOrm
    field :name, :string
    set   :users, :string
    validates_presence_of :name

    @@sources = []

    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        super(fields)
      end
    end

    def delete
      @@sources = []
      super
    end

    def delete_sources
      @@sources = []
    end

    def partition_sources(partition,user_id)
      names = []
      @@sources.each do |source|
        s = Source.load(source,{:app_id => self.name,
          :user_id => user_id})
        if s.partition == partition
          names << s.name
        end
      end
      names
    end

    def sources
      @@sources.uniq!
      # Sort sources array by priority
      @@sources = @@sources.sort_by { |s| Source.load(s, {:app_id => self.name, :user_id => '*'}).priority }
    end
  end
end