require 'rack/test'
require 'rspec'

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect.rb')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

def compress(path)
  path.sub!(%r[/$],'')
  archive = File.join(path,File.basename(path))+'.zip'
  FileUtils.rm archive, :force=>true
  Zip::File.open(archive, 'w') do |zipfile|
    Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
      zipfile.add(file.sub(path+'/',''),file)
    end
  end
end
