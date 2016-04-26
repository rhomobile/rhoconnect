var app = require('ballroom');
var rc_helpers = require('rhoconnect_helpers');
//var RhoInternalJsBenchAdapter = require('../../models/js/rho_internal_js_bench_adapter');

app.controllerName('RhoInternalJsBenchAdapter');
app.registerHandler('sync');

// app.post('/',{}, function(req,resp){
//   console.log("inside of controller post");
//   var result = {'id':req.params};
//   resp.send(result);
// });