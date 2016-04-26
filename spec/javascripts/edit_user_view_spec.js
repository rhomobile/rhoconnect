// describe("EditUserView", function(){
// 	
// 	beforeEach(function(){
// 		var session = new Session();
// 		session.setAuthenticated('true');
// 		session.setApiKey('testtoken');
// 		this.editUserView = new App.Views.EditUser();
// 	});
// 	
// 	afterEach(function(){
// 		var session = new Session();
// 		session.setAuthenticated('false');
// 		session.setApiKey(null);
// 	});
// 	
// 	it("should have render initial html",function(){
// 		this.UserRenderSpy = sinon.spy(this.editUserView,'render');
// 			
// 		this.editUserView.render();
// 		expect(this.UserRenderSpy).toHaveBeenCalledOnce();
// 	});
// 	
// 	it("should call edit",function(){
// 		this.editUserRenderSpy = sinon.spy(this.editUserView,'edit');
// 		sinon.stub(jQuery,'ajax').yieldsTo("success");
// 		function myevent(){
// 			this.preventDefault=function(){return true;}
// 		}
// 		e = new myevent();
// 		
// 		this.editUserView.edit(e);
// 		expect(this.editUserRenderSpy).toHaveBeenCalledOnce();
// 		jQuery.ajax.restore();
// 	});
// 	
// 	it("should have correct html rendered ",function(){
// 		var title = this.editUserView.el.innerHTML.search('Change Admin Password');
// 		expect(title).toBeGreaterThan(0);
// 		
// 		var password = this.editUserView.el.innerHTML.search('Password');
// 		expect(password).toBeGreaterThan(0);
// 		
// 	})
// });