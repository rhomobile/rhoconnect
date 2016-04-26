var Request = function(){
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

	this.__defineGetter__("model",function(){
		return model;
	});

	this.__defineSetter__("model",function(arg){
		model = arg;
	});
};
module.exports = Request;
