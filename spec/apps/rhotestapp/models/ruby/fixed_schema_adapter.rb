class FixedSchemaAdapter < SourceAdapter
  def initialize(source)
    super(source)
  end
  
  def query(params=nil)
    @result = Store.get_data('test_db_storage')
  end
  
  def schema
    {
      'version' => '1.0',
      'property' => {
        'name' => 'string',
        'brand' => 'string',
        'price' => 'string',
        'image_url_cropped' => 'blob,overwrite',
        'image_url' => 'blob'
      },
      'index' => {
        'by_name_brand' => 'name,brand'
      },
      'unique_index' => {
        'by_price' => 'price'
      }
    }.to_json
  end
end