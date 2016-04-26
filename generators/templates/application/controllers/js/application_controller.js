var app = require('ballroom');
var rc = require('rhoconnect_helpers');
app.controllerName('Application');

app.post('/login',{'rc_handler':'authenticate',
  'deprecated_route': {'verb': 'post', 'url': ['/application/clientlogin']}}, function(req,resp){
  var login = req.params.login;
  var password = req.params.password;
  resp.send(true);
});

app.get('/rps_login',{'rc_handler':'rps_authenticate'}, function(req,resp){
  var login = req.params.login;
  var password = req.params.password;
  resp.send(true);
});
