var util = require('util');

//Setup exception handlers
var AbstractException = function (resp,msg,constr) {
  Error.captureStackTrace(this, constr || this);
  this.message = msg || 'Error';
  resp.exception = {"error": {"error_type": this.name, "message": this.message, "stacktrace": this.stack} };
  resp.send(null);
};

var Exception = function (resp,msg) {
  Exception.super_.call(this, resp, msg, this.constructor);
};

var LoginException = function (resp,msg) {
  LoginException.super_.call(this, resp, msg, this.constructor);
};

var LogoffException = function (resp,msg) {
  LogoffException.super_.call(this, resp, msg, this.constructor);
};

var ServerTimeoutException = function (resp,msg) {
  ServerTimeoutException.super_.call(this, resp, msg, this.constructor);
};

var ServerErrorException = function (resp,msg) {
  ServerErrorException.super_.call(this, resp, msg, this.constructor);
};

var ObjectConflictErrorException = function (resp,msg) {
  ObjectConflictErrorException.super_.call(this, resp, msg, this.constructor);
};

// Setup the types for each exception
util.inherits(AbstractException, Error);
util.inherits(Exception, AbstractException);
util.inherits(LoginException, AbstractException);
util.inherits(LogoffException, AbstractException);
util.inherits(ServerTimeoutException, AbstractException);
util.inherits(ServerErrorException, AbstractException);
util.inherits(ObjectConflictErrorException, AbstractException);


// Default names
AbstractException.prototype.name            = 'AbstractException';
Exception.prototype.name                    = 'Exception';
LoginException.prototype.name               = 'LoginException';
LogoffException.prototype.name              = 'LogoffException';
ServerTimeoutException.prototype.name       = 'ServerTimeoutException';
ServerErrorException.prototype.name         = 'ServerErrorException';
ObjectConflictErrorException.prototype.name = 'ObjectConflictErrorException';

// Public exceptions
module.exports.Exception                    = Exception;
module.exports.LoginException               = LoginException;
module.exports.LogoffException              = LogoffException;
module.exports.ServerTimeoutException       = ServerTimeoutException;
module.exports.ServerErrorException         = ServerErrorException;
module.exports.ObjectConflictErrorException = ObjectConflictErrorException;
