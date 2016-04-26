describe("Home", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    source = new Source();
	  
		sinon.stub(source,'fetch');
		sinon.stub(source,'save');
		
		adapter = new Adapter();
		sinon.stub(adapter, 'set_adapter');
		sinon.stub(adapter, 'get_adapter');
		
	    confirmStub = sinon.stub(window, 'confirm');
		confirmStub.returns(true);
		sinon.stub(jQuery,'ajax');
		this.homeView = new App.Views.Home({model : source, model2 : adapter});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		confirmStub.restore();
		jQuery.ajax.restore();
	});
	
	it("should have render initial html",function(){
		this.indexRenderSpy = sinon.spy(this.homeView,'render');
			
		this.homeView.render();
		expect(this.indexRenderSpy).toHaveBeenCalledOnce();
	});
	
});