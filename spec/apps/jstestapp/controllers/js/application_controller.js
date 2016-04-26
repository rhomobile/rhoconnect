var app = require('ballroom');
var rc = require('rhoconnect_helpers');
var Store = rc.Store;
app.controllerName('Application');

app.post('/login',{'rc_handler':'authenticate'}, function(req,resp){
  console.log("inside application_controller.js");
  var login = req.params.login;
  var password = req.params.password;
  if(login === 'storeapitest') {
    resp.params = ['loginkey',login]
    Store.putValue(resp, function(resp){
      resp.send(true);
    });
  } else {
    resp.send(true);
  }
});
