var Response = require('./response');
var Request = require('./request');

var router = function(json,send){
  switch(json['route']){
    case 'request':
      try {
        var request = new Request();
        var resp1 = new Response();
        request.params = json['args'];
        request.header = {'request_id':json['request_id'],'route':json['route']};
        request.model = json['model'];
        resp1.currentUser = json['user'];
        resp1.header = {'request_id':json['request_id'],'route':'response'};

        //if calling model function directly load file first
        if(json['klss'] !== undefined){
          var model_dir = '';
          if(json['klss'].match(/rho_internal/g) !== null){
            model_dir = __dirname + "/../lib/rhoconnect/predefined_adapters/models/js/";
          }
          else if(process.argv[3] == 'test' ){
            model_dir = process.argv[4] + "/models/js/";
          }
          else{
            model_dir = process.cwd() + "/models/js/";
          }
          var mod = require(model_dir + json['klss'] + '.js');
          mod[json['function']](resp1);
        }
        else{
          registeredRoutes[json['url']](request,resp1);
        }
        break;
      }
      catch(e){
        console.error(e.stack || e.toString());
        resp1.exception = {"error": {"error_type": e.name, "message": e.message, "stacktrace": e.stack} };
        resp1.send(null);
      }
      break;
    case 'response':
      try {
        var cback = json['callback'];
        json['callback'] = undefined;
        var resp2 = new Response();
        resp2.header = {'request_id':json['request_id'],'route':'response'};
        resp2.result = json['result'];


        rhoconnectCallbacks[cback](resp2);
        delete rhoconnectCallbacks[cback];
      } catch(e) {
        console.error(e.stack || e.toString());
        resp2.exception = {"error": {"error_type": e.name, "message": e.message, "stacktrace": e.stack} };
        resp2.send(null);
      }
      break;
    case 'deregister':
      var br = require('ballroom');
      br.exitNodejs();
      break;
    default : break;
  }
};

exports.router = router;