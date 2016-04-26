describe("Admins routes", function() {
  beforeEach(function() {
    this.router = new App.Controllers.Admins();
    this.routeSpy = sinon.spy();
	sinon.stub(jQuery,'ajax')
    try {
      Backbone.History.start({silent:true, pushState:true});
    } catch(e) {}
    this.router.navigate("test");
  });

  afterEach(function(){
	jQuery.ajax.restore();
  });
  
  it("fires the index route with a blank hash", function() {
       this.router.bind("route:index", this.routeSpy);
       this.router.navigate("", true);
       expect(this.routeSpy).toHaveBeenCalledOnce();
       expect(this.routeSpy).toHaveBeenCalledWith();
     });
    
    it("fires the home route with a blank hash", function() {
          this.router.bind("route:index", this.routeSpy);
          this.router.navigate("home", true);
          expect(this.routeSpy).toHaveBeenCalledOnce();
          expect(this.routeSpy).toHaveBeenCalledWith();
     });
   
   it("fires the show_source route", function() {
    	this.router.bind('route:show_source', this.routeSpy);
    	this.router.navigate("sources/1/tuser/tdoc/tclient", true);
    	expect(this.routeSpy).toHaveBeenCalledOnce();
    	expect(this.routeSpy).toHaveBeenCalledWith("1","tuser","tdoc","tclient");
    });
  
    it("fires the login route", function() {
     	this.router.bind('route:login', this.routeSpy);
     	this.router.navigate("login", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the logout route", function() {
     	this.router.bind('route:logout', this.routeSpy);
     	this.router.navigate("logout", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the get_doc route", function() {
     	this.router.bind('route:get_doc', this.routeSpy);
     	this.router.navigate("doc/testdoc/2", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith("testdoc","2");
    });
   
    it("fires the server_doc route", function() {
     	this.router.bind('route:server_doc', this.routeSpy);
     	this.router.navigate("docselect", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the adapter route", function() {
     	this.router.bind('route:adapter', this.routeSpy);
     	this.router.navigate("adapter", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the users route", function() {
     	this.router.bind('route:users', this.routeSpy);
     	this.router.navigate("users", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the new_user route", function() {
     	this.router.bind('route:new_user', this.routeSpy);
     	this.router.navigate("users/new", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the show_user route", function() {
     	this.router.bind('route:show_user', this.routeSpy);
     	this.router.navigate("user/1", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith("1");
    });
   
    it("fires the new_ping route", function() {
     	this.router.bind('route:new_ping', this.routeSpy);
     	this.router.navigate("user/newping/1", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith("1");
    });
   
    it("fires the new_ping_all route", function() {
     	this.router.bind('route:new_ping_all', this.routeSpy);
     	this.router.navigate("users/newping", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith();
    });
   
    it("fires the user_device route", function() {
     	this.router.bind('route:user_device', this.routeSpy);
     	this.router.navigate("device/1/2", true);
     	expect(this.routeSpy).toHaveBeenCalledOnce();
     	expect(this.routeSpy).toHaveBeenCalledWith("1","2");
    });
 
});

