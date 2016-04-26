var ruby_functions = require('rhoconnect_helpers');

var query = function(resp){
	var result = "success";
	resp.send(result);
}

var sync = function(resp){
	
}

var login = function(resp){
	var result = "success";
	resp.send(result);
}

var logoff = function(resp){
	var result = "logout";
	resp.send(result);
}

exports.query = query;
exports.sync = sync;
exports.login = login;
exports.logoff = logoff;