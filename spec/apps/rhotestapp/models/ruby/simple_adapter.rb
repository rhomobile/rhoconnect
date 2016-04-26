class SimpleAdapter < SourceAdapter
  # initialize method created by source generator (Rhoconnect version < 2.2.0)
  def initialize(source)
    super(source)
  end
 
  def login
    unless _is_empty?(current_user.login)
      true
    else
      raise SourceAdapterLoginException.new('Error logging in')
    end
  end
 
  def query(params=nil)
    @result
  end
  
  def search(params=nil,txt='')
    params[:foo] = 'bar' # this is for 'chaining' test
    if params['search'] == 'bar'
      @result = {'obj'=>{'foo'=>'bar'}} 
      # this is for 'chaining' test, addind 'iPhone' to trogger Sample adapter search result
      params['name'] = 'iPhone'  
    end
    @result
  end
 
  def sync
    super
  end
 
  def create(create_hash)
    'obj4'
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
end