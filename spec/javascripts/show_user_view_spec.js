describe("ShowUserView", function(){
	
	beforeEach(function(){
		var session = new Session();
		session.setAuthenticated('true');
		session.setApiKey('testtoken');
	    user = new User();
	    user.set('name','testname');
		source = new Source();
		
		sinon.stub(jQuery,'ajax')
		sinon.stub(source,'fetch')
	
	    confirmStub = sinon.stub(window, 'confirm');
		confirmStub.returns(true);
		
		this.showUserView = new App.Views.ShowUser({model : user});
	});
	
	afterEach(function(){
		var session = new Session();
		session.setAuthenticated('false');
		session.setApiKey(null);
		jQuery.ajax.restore();
		confirmStub.restore();
	});
	
	it("should have render initial html",function(){
		this.showUserSpy = sinon.spy(this.showUserView,'render');
			
		this.showUserView.render();
		expect(this.showUserSpy).toHaveBeenCalledOnce();
	});
	
	it("should delete user",function(){
		this.deleteUserDeleteSpy = sinon.spy(this.showUserView,'delete_user');
		function myevent(){
			this.preventDefault=function(){return true;}
		}
		e = new myevent();
		
		this.showUserView.delete_user(e);
		expect(this.deleteUserDeleteSpy).toHaveBeenCalledOnce();
	});
	
	it("should have correct html rendered ",function(){
		var title = this.showUserView.el.innerHTML.search("User: testname");
		expect(title).toBeGreaterThan(0);	
	})
});