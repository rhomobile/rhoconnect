// describe("Admins", function() {
// 
//   beforeEach(function() {
//    	 this.router      = new App.Controllers.Admins();
// 	 this.session     = new Session();
// 	 this.sessionStub = sinon.stub(this.session,"getAuthenticated").returns("true")
// 
// 	 this.home = new App.Views.Home({model:new Source()});
// 	 this.fetchStub = sinon.stub(this.model.home,'fetch').returns(null);
// 	 this.fetchSave = sinon.stub(this.model.home,'save').returns(null);
//   });
//   
//   afterEach(function() {
//     
//   });
// 
//   it("creats a new Index page if not logged in",function(){
// 	
// 	
// 	 this.router.index();
// 	
// 	 expect(sessionStub).toHaveBeenCalledOnce();
// 	 //expect(this.fetchStub).toHaveBeenCalledOnce();
// 	 //expect(this.fetchSave).toHaveBeenCalledOnce();
//   });
// 
// });
