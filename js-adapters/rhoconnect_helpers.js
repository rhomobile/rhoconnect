var exceptions = require('./exceptions');

var stashResult = function(resp){
	var json = {};
	var callback = function(){};
  json['function'] = 'stash_result';
	json['args'] = resp.params;
  json['callback'] = callback;
	resp.send(json);
};

var source = function(resp,callback){
	var json = {};
  json['function'] = 'source';
	json['args'] = '';
  json['callback'] = callback;
	resp.send(json);
};

var getData = function(resp,callback){
	var json = {};
  json['function'] = 'get_data';
	json['args'] = '';
  json['callback'] = callback;
	resp.send(json);
};

var Store = function(){

	this.putValue = function(resp,callback){
		var json = this.formatJson('put_value',resp.params,callback);
		resp.send(json);
	};
	this.getValue = function(resp,callback){
		var json = this.formatJson('get_value',resp.params,callback);
		resp.send(json);
	};
	this.putData = function(resp,callback){
		var json = this.formatJson('put_data',resp.params,callback);
		resp.send(json);
	};
	this.getData = function(resp,callback){
		var json = this.formatJson('get_data',resp.params,callback);
		resp.send(json);
	};
	this.deleteData = function(resp,callback){
		var json = this.formatJson('delete_data',resp.params,callback);
		resp.send(json);
	};

	this.formatJson = function(method,args,callback){
		var json = {};
		json['kls'] = 'Store';
		json['function'] = method;
		json['args'] = args;
		json['callback'] = callback;
		json['route'] = 'request';
		return json;
	};
};

exports.stashResult = stashResult;
exports.getData = getData;
exports.source = source;
module.exports.Store = new Store();
module.exports.Exception                    = exceptions.Exception;
module.exports.LoginException               = exceptions.LoginException;
module.exports.LogoffException              = exceptions.LogoffException;
module.exports.ServerTimeoutException       = exceptions.ServerTimeoutException;
module.exports.ServerErrorException         = exceptions.ServerErrorException;
module.exports.ObjectConflictErrorException = exceptions.ObjectConflictErrorException;