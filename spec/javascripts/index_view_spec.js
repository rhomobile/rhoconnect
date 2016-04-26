describe("Index", function(){
	
	beforeEach(function(){
		this.indexView = new App.Views.Index;
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
	})
	
	it("should have render initial html",function(){
		this.indexRenderSpy = sinon.spy(this.indexView,'render');
		this.indexView.render();
		expect(this.indexRenderSpy).toHaveBeenCalledOnce();
	});
	
	it("should call login and set auth",function(){
		this.indexLoginSpy = sinon.spy(this.indexView,'login')
		var stub = sinon.stub(jQuery,'ajax').yieldsTo("success","testtoken");
		function myevent(){
			this.preventDefault=function(){return true;}
		}
		e = new myevent();
		this.indexView.login(e);
		
		var session = new Session();
		expect(session.getAuthenticated()).toEqual('true')
		expect(session.getApiKey()).toEqual('testtoken')
		jQuery.ajax.restore();
	});
	
	it("should have correct html rendered",function(){
		var login = this.indexView.el.innerHTML.search('Login');
		expect(login).toBeGreaterThan(0);
		
		var password = this.indexView.el.innerHTML.search('Password');
		expect(password).toBeGreaterThan(0);	
	})
	
});
