describe("NewUserView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    user = new User();
	
		sinon.stub(user,'create_user')
	
		this.newUserView = new App.Views.NewUser({model : user});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		user.create_user.restore()
	});
	
	it("should have render initial html",function(){
		this.newUserRenderSpy = sinon.spy(this.newUserView,'render');
			
		this.newUserView.render();
		expect(this.newUserRenderSpy).toHaveBeenCalledOnce();
	});
	
	it("should call create user",function(){
		this.createUserRenderSpy = sinon.spy(this.newUserView,'create_user');
		function myevent(){
			this.preventDefault=function(){return true;}
		}
		e = new myevent();
		this.newUserView.create_user(e);
		expect(this.createUserRenderSpy).toHaveBeenCalledOnce();
	});
	
	it("should have correct html rendered ",function(){
		var title = this.newUserView.el.innerHTML.search('New user');
		expect(title).toBeGreaterThan(0);	
	})
});