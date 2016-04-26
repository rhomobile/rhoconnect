describe("SourceDocsView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    source = new Source();
	    source.set("source_id",'source_id');
		
		sinon.stub(jQuery,'ajax')
	
		this.sourceDocsView = new App.Views.SourceDocs({model : source});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
	});
	
	it("should have render initial html",function(){
		this.sourceDocsSpy = sinon.spy(this.sourceDocsView,'render');
			
		this.sourceDocsView.render('source_id');
		expect(this.sourceDocsSpy).toHaveBeenCalledOnce();
	});
		
	it("should have correct html rendered ",function(){
		var title = this.sourceDocsView.el.innerHTML.search("Attributes");
		expect(title).toBeGreaterThan(0);
		
		var title2 = this.sourceDocsView.el.innerHTML.search("Documents");
		expect(title2).toBeGreaterThan(0);	
	})
});