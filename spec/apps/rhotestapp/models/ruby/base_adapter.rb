class BaseAdapter < SourceAdapter
  def initialize(source)
    super(source)
  end
 
  def query(params=nil)
    @result
  end
end