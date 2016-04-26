module Rhoconnect
  module Handler
    module Helpers
      module Binding
    		def bind_handler(method_name, method_proc)
    		  # do nothing if already bound
    		  return method_proc if method_proc.is_a?Method

    		  self.class.send :define_method, method_name, method_proc
    		  method = self.class.instance_method(method_name)
    		  self.class.send :remove_method, method_name
    		  # bind it to self
    		  method.bind(self)
    		end
      end
    end
  end
end