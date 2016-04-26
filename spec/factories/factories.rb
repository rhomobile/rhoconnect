Factory.define :clients do |c|
  c.add_attribute :device_type => 'Apple',
  c.add_attribute :device_pin  => 'abcd',
  c.add_attribute :user_id     => {|u| u.id }
  c.add_attribute :device_port => '3333',
  c.add_attribute :app_id      => {|a| a.id },
  c.add_attriubte :source_name => 'SampleAdapter'
end

Factory.define :sources do |s|
  s.name     :name     => 'SampleAdapter',
  s.url      :url      => 'http://example.com',
  s.login    :login    => 'testuser',
  s.password :password => 'testpass',
  s.app_id   :app_id   => {|a| a.id }
  s.user_id  :user_id  => {|u| u.id }
end