describe("NewPingView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
	});
	
	it("should have render initial html with name",function(){
		sinon.stub(jQuery,'ajax');
		
		var user = new User();
		user.set('name','testname');
		this.newPingView = new App.Views.NewPing({model : user});
		this.PingRenderSpy = sinon.spy(this.newPingView,'render');
		this.newPingView.render();
		expect(this.PingRenderSpy).toHaveBeenCalledOnce();
		jQuery.ajax.restore();
	});
	
	it("should have render initial html with no name",function(){
		sinon.stub(jQuery,'ajax');
		var user = new User();
		sinon.stub(user,'get_users');
		this.newPingView = new App.Views.NewPing({model : user});
		this.PingRenderSpy = sinon.spy(this.newPingView,'render');
		this.newPingView.render();
		expect(this.PingRenderSpy).toHaveBeenCalledOnce();
		
		user.get_users.restore();
		jQuery.ajax.restore();
	});
	
	it("should have correct html rendered ",function(){
		sinon.stub(jQuery,'ajax');
		var user = new User();
		this.newPingView = new App.Views.NewPing({model : user});
		var title = this.newPingView.el.innerHTML.search('Ping User/s');
		expect(title).toBeGreaterThan(0);
		jQuery.ajax.restore();
	})
});