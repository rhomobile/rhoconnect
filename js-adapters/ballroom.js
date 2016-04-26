var redis = require('redis'),
    fs = require('fs'),
    util = require('util'),
    EventEmitter = require('events').EventEmitter,
    registerEE = new EventEmitter(),
    routes = require('./router'),
    redis_url = require('url').parse(process.env.REDIS_URL),
    client_sub = redis.createClient(redis_url.port, redis_url.hostname),
    client_pub = redis.createClient(redis_url.port, redis_url.hostname),
    pub_channel = process.argv[2] + "-RedisPUB",
    rcHelpers = require('./rhoconnect_helpers');

if(redis_url.auth) {
  client_sub.auth(redis_url.auth.split(":")[1]);
  client_pub.auth(redis_url.auth.split(":")[1]);
}

//define global hash functions to store callbacks, routes
rhoconnectCallbacks = {};
registeredRoutes = {};
registeredControllers = {};
registeredModels = {};
var _c_name = null;
var _m_name = null;

//TODO: This has to be changed in the future
// The only reason for this - on Windows Node.js
// dies and leaves hanging opened sockets
// Proper way: have a global domain as a safety valve
process.on('uncaughtException', function(err) {
  client_sub.quit();
  client_pub.quit();
});

var controllerName = function(n){
  _c_name = n;
  registeredControllers[_c_name] = {};
  registeredControllers[_c_name]['routes'] = [];
  registeredControllers[_c_name]['defaults'] = [];
  this.modelName(_c_name);
};

var modelName = function(n){
  // TODO: Need to map directly to registeredModels
  registeredControllers[_c_name]['model'] = n;
};

var exitNodejs = function(){
  send({"exit": true});
  process.exit(0);
};

var listen = function(channel){
  client_sub.subscribe(channel);
  client_sub.on("message", function(channel, message) {
    //console.error("message nodejs recvd:" + message)
    var json = JSON.parse(message);
    try{
      routes.router(json,send);
    }
    catch(e){
      console.error("Node.js error caught: "+ e);
      console.error("Backtrace: " + e.stack);
    }
  });
};

var send = function(json){
  if(json['callback']){
    var h_id = guid();
    rhoconnectCallbacks[h_id] = json['callback'];
    json['callback'] = h_id;
  }
  var j = JSON.stringify(json);
  client_pub.publish(pub_channel,j);
};

var registerHandler = function(name) {
  switch(name){
    case 'sync':
      this.defaults(
        {
          admin_required: false,
          login_required: true,
          source_required: true,
          client_required: true
        }
      );

      this.get('/', {"rc_handler":"query",
        "deprecated_route": {"verb": "get", "url": ['/api/application', '/application', '/api/application/query']}}, function(req,resp){
        loadModel(req.model).query(resp);
      });

      this.post('/', {"rc_handler":"cud",
        "deprecated_route": {"verb": "post", "url": ['/api/application', '/application', '/api/application/queue_updates']}}, function(req,resp){
        var operationCall = req.params.operation;
        if(operationCall === 'delete') {
          operationCall = 'del';
        }
        loadModel(req.model)[operationCall](resp);
      });

      this.put('/:id', {"rc_handler":"update"}, function(req,resp){
        loadModel(req.model).update(resp);
      });

      this.del('/:id', {"rc_handler":"delete"}, function(req,resp){
        loadModel(req.model).del(resp);
      });
      break;
    default: break;
  }
};

var register = function(){
  var controller_dir = "";
  var model_dir = "";
  var predefined_model_dir = "";
  var predefined_controller_dir = "";
  try{
    if(process.argv[3] == 'test' ){
      controller_dir = process.argv[4] + "/controllers/js/";
      model_dir = process.argv[4] + "/models/js/";
    }
    else{
      controller_dir = process.cwd() + "/controllers/js/";
      model_dir = process.cwd() + "/models/js/";
    }
    predefined_controller_dir = __dirname + "/../lib/rhoconnect/predefined_adapters/controllers/js/";
    predefined_model_dir = __dirname + "/../lib/rhoconnect/predefined_adapters/models/js/";
    if(fs.existsSync(model_dir)){
      var modelFiles = fs.readdirSync(model_dir);
      modelFiles.forEach(function(file){
        //console.error("requiring model file: " + file);
        var model = require(model_dir + file);
        var functions = Object.keys(model);
        mapModelFunctions(file.split(".")[0],functions);
      });
    }
    if(fs.existsSync(controller_dir)){
      var controllerFiles = fs.readdirSync(controller_dir);
      controllerFiles.forEach(function(file){
        //console.error("requiring controller file: " + file);
        require(controller_dir + file);
        _c_name = null;
      });
    }
    if(fs.existsSync(predefined_model_dir)){
      var modelFiles = fs.readdirSync(predefined_model_dir);
      modelFiles.forEach(function(file){
        //console.log("requiring model file: " + predefined_model_dir + file);
        var model = require(predefined_model_dir + file);
        var functions = Object.keys(model);
        mapModelFunctions(file.split(".")[0],functions);
      });
    }
    if(fs.existsSync(predefined_controller_dir)){
      var controllerFiles = fs.readdirSync(predefined_controller_dir);
      controllerFiles.forEach(function(file){
        //console.log("requiring controller file: " + predefined_controller_dir + file);
        require(predefined_controller_dir + file);
        _c_name = null;
      });
    }
  }
  catch(e){
    console.error("Error loading JavaScript files.");
    throw(e);
  }
  registerEE.emit('register_complete');
};

// this event will be called when all files have been registered
registerEE.on('register_complete',function(){
  var json = {};
  json['route'] = 'register';
  json['result'] = registeredControllers;
  json['models'] = registeredModels;
  send(json);
});


var get = function(url,options,callback){
  var key = 'get_rjs_' + _c_name + '_rjs_' + url + '_rjs_' + format_options(options);
  registeredRoutes[key] = callback;
  registeredControllers[_c_name]['routes'].push(key);
};

var post = function(url,options,callback){
  var key = 'post_rjs_'  + _c_name + '_rjs_' + url + '_rjs_' + format_options(options);
  registeredRoutes[key] = callback;
  registeredControllers[_c_name]['routes'].push(key);
};

var put = function(url,options,callback){
  var key = 'put_rjs_'  + _c_name + '_rjs_' + url + '_rjs_' + format_options(options);
  registeredRoutes[key] = callback;
  registeredControllers[_c_name]['routes'].push(key);
};

var del = function(url,options,callback){
  var key = 'delete_rjs_'  + _c_name + '_rjs_' + url + '_rjs_' + format_options(options);
  registeredRoutes[key] = callback;
  registeredControllers[_c_name]['routes'].push(key);
};

var defaults = function(hsh){
  registeredControllers[_c_name]['defaults'].push(hsh);
};

var format_options = function(opts){
  return JSON.stringify(opts);
};

function guid() {
    return (((1+Math.random())*0x100000000)|0).toString(16).substring(1);
}

function mapModelFunctions(model,functions){
  registeredModels[model] = [];
  for(var i = 0;i< functions.length;i++){
    registeredModels[model].push(functions[i]);
  }
}

function loadModel(name) {
  var prefix = process.cwd();
  if(name.match(/rho_internal/g) !== null){
    prefix = __dirname + "/../lib/rhoconnect/predefined_adapters";
  } else if(process.argv[3] === 'test') {
    prefix = process.argv[4];
  }
  return require(prefix + "/models/js/" + name);
}

exports.controllerName = controllerName;
exports.modelName = modelName;
exports.register = register;
exports.registerHandler = registerHandler;
exports.send = send;
exports.listen = listen;
exports.get = get;
exports.put = put;
exports.del = del;
exports.post = post;
exports.defaults = defaults;
exports.exitNodejs = exitNodejs;
exports.stashResult = rcHelpers.stashResult;
exports.source = rcHelpers.source;
module.exports.Store = rcHelpers.Store;