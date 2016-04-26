describe("SetAdapterView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    adapter = new Adapter();
	    
		sinon.stub(jQuery,'ajax')
	    var domain = 'http://test.com'
		this.setAdapterView = new App.Views.SetAdapter({model : adapter});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
	});
	
	it("should have render initial html",function(){
		this.setAdapterSpy = sinon.spy(this.setAdapterView,'render');
			
		this.setAdapterView.render();
		expect(this.setAdapterSpy).toHaveBeenCalledOnce();
	});
	
});