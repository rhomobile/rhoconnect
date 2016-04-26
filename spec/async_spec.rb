require File.join(File.dirname(__FILE__),'api','api_helper')

# these specs are executed only with Async support
if not defined?(JRUBY_VERSION)
  describe "BasicEventMachineTest with Threads" do
    it "should run EventMachine gracefully and schedule callback execution in thread" do
      f = Fiber.current
      operation = proc { res = 1 }
      operation_res = 0
      callback = proc { |proc_res| operation_res = proc_res; f.resume }
      EventMachine.defer operation, callback
      Fiber.yield
      # this code should be executed only after the thread's return
      operation_res.should == 1
    end
  end
end