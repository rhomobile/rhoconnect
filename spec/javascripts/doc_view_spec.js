describe("DocView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
		
	    doc = new Doc();
	    doc.set("dbkey",'testkey');
	
		sinon.stub(doc,'get_doc')
	
		this.docView = new App.Views.Doc({model : doc});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
	});
	
	it("should have render initial html",function(){
		this.docRenderSpy = sinon.spy(this.docView,'render');
			
		this.docView.render();
		expect(this.docRenderSpy).toHaveBeenCalledOnce();
	});
	
});