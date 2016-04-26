# This class has dubious semantics and we only have it so that
# people can write params[:key] instead of params['key']
# and they get the same value for both keys.

module Rhoconnect
  class RhoHashWithIndifferentAccess < Hash
    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      end
    end

    def default(key = nil)
      if key.is_a?(Symbol) && include?(key = key.to_s)
        self[key]
      else
        super
      end
    end

    alias_method :regular_writer, :[]= #unless method_defined?(:regular_writer)
    alias_method :regular_update, :update #unless method_defined?(:regular_update)

    # Assigns a new value to the hash:
    #
    #   hash = HashWithIndifferentAccess.new
    #   hash[:key] = "value"
    #
    def []=(key, value)
      regular_writer(convert_key(key), convert_value(value))
    end

    # Updates the instantized hash with values from the second:
    # 
    #   hash_1 = HashWithIndifferentAccess.new
    #   hash_1[:key] = "value"
    # 
    #   hash_2 = HashWithIndifferentAccess.new
    #   hash_2[:key] = "New Value!"
    # 
    #   hash_1.update(hash_2) # => {"key"=>"New Value!"}
    # 
    def update(other_hash)
      other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
      self
    end

    alias_method :merge!, :update

    # Checks the hash for a key matching the argument passed in:
    #
    #   hash = HashWithIndifferentAccess.new
    #   hash["key"] = "value"
    #   hash.key? :key  # => true
    #   hash.key? "key" # => true
    #
    def key?(key)
      super(convert_key(key))
    end

    alias_method :include?, :key?
    alias_method :has_key?, :key?
    alias_method :member?, :key?

    def stringify_keys!; self end
    def symbolize_keys!; self end
    def to_options!; self end

    protected
      def convert_key(key)
        key.kind_of?(Symbol) ? key.to_s : key
      end

      def convert_value(value)
        value
      end
  end
end

class Hash  
  public
  def with_indifferent_access
    hash = Rhoconnect::RhoHashWithIndifferentAccess.new(self)
    hash.default = self.default
    hash
  end
end