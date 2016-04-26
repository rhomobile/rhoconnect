describe("UsersView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    users = new User();
		
		sinon.stub(jQuery,'ajax')
	
		this.usersView = new App.Views.Users({model : users});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
	});
	
	it("should have render initial html",function(){
		this.usersDocsSpy = sinon.spy(this.usersView,'render');
			
		this.usersView.render('source_id');
		expect(this.usersDocsSpy).toHaveBeenCalledOnce();
	});
		
	it("should have correct html rendered ",function(){
		var title = this.usersView.el.innerHTML.search("Users");
		expect(title).toBeGreaterThan(0);
		
		var title2 = this.usersView.el.innerHTML.search("Create User");
		expect(title2).toBeGreaterThan(0);	
	})
});