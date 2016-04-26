describe("ServerDocView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    doc = new Doc();
	
		sinon.stub(jQuery,'ajax')
	
		this.serverDocView = new App.Views.ServerDoc({model : doc});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
	});
	
	it("should have render initial html",function(){
		this.serverDocRenderSpy = sinon.spy(this.serverDocView,'render');
			
		this.serverDocView.render();
		expect(this.serverDocRenderSpy).toHaveBeenCalledOnce();
	});
	
	it("should clear doc",function(){
		this.serverDocClearSpy = sinon.spy(this.serverDocView,'clear');
	    doc.set('dbkey','testdbkey');
		function myevent(){
			this.preventDefault=function(){return true;}
		}
		e = new myevent();
		this.serverDocView.clear(e);
		expect(this.serverDocClearSpy).toHaveBeenCalledOnce();
	});
	
	it("should have correct html rendered ",function(){
		var title = this.serverDocView.el.innerHTML.search('Document&nbsp;');
		expect(title).toBeGreaterThan(0);	
	})
});