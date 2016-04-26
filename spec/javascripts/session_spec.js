describe("Session", function(){
	beforeEach(function(){
		this.session = new Session;	
	});
	
	it("should have set session key",function(){
		this.session.setApiKey("testkey")
		expect(this.session.getApiKey()).toEqual('testkey')
	});
	
	it("should have set authentication",function(){
		this.session.setAuthenticated("true")
		expect(this.session.getAuthenticated()).toEqual('true')
	});
})