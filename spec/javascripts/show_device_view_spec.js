describe("ShowDeviceView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    client = new Client();
		client.set('device_id', 'testdeviceid');
		client.set('user_id', 'user_id');
	
		sinon.stub(jQuery,'ajax')
		confirmStub = sinon.stub(window, 'confirm');
		confirmStub.returns(true);
		
		this.setdeviceView = new App.Views.ShowDevice({model : client});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
		confirmStub.restore();
	});
	
	it("should have render initial html",function(){
		this.setDeviceSpy = sinon.spy(this.setdeviceView,'render');
			
		this.setdeviceView.render();
		expect(this.setDeviceSpy).toHaveBeenCalledOnce();
	});
	
	it("should delete device",function(){
		this.setDeviceDeleteSpy = sinon.spy(this.setdeviceView,'delete_device');
			
		this.setdeviceView.delete_device();
		expect(this.setDeviceDeleteSpy).toHaveBeenCalledOnce();
	});
	
	it("should have correct html rendered ",function(){
		var title = this.setdeviceView.el.innerHTML.search("Device: testdeviceid");
		expect(title).toBeGreaterThan(0);	
	})
});