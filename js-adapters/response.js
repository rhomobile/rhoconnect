Object.extend = function(destination, source) {
    for (var property in source) {
        if (source.hasOwnProperty(property)) {
            destination[property] = source[property];
        }
    }
    return destination;
};

var Response = function(){
	var exception = "";

	this.__defineGetter__("params",function(){
		return params;
	});

	this.__defineSetter__("params",function(arg){
		params = arg;
	});

	this.__defineGetter__("header",function(){
		return header;
	});

	this.__defineSetter__("header",function(arg){
		header = arg;
	});

	this.__defineGetter__("exception",function(){
		return exception;
	});

	this.__defineSetter__("exception",function(arg){
		exception = arg;
	});

	this.__defineGetter__("currentUser",function(){
		return currentUser;
	});

	this.__defineSetter__("currentUser",function(arg){
		currentUser = arg;
	});

	this.send = function(data){
		var ballroom = require("./ballroom");
		var user_json = {};

		//if callback we are sending request to ruby
		if(data && data['callback']){
			this.params = null;
			this.header['route'] = 'request';
			user_json = data;
		}
		else{
			user_json["result"] = data;
			this.header['route'] = 'response';
		}
		Object.extend(user_json,this.params);
		Object.extend(user_json,this.header);
		Object.extend(user_json,this.exception);
		ballroom.send(user_json);
	};
};
module.exports = Response;
