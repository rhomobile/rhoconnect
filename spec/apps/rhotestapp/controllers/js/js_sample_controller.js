var JsSample = require('../../models/js/js_sample');
var app = require('ballroom');
var rc_helpers = require('rhoconnect_helpers');

app.controllerName('JsSample');
app.registerHandler('sync');

app.get('/custom_route',{}, function(req,resp){
	JsSample.getUser(resp);
});

app.get('/custom_route2',{}, function(req,resp){
	JsSample.getSource(resp);
});

app.get('/custom_route3',{}, function(req,resp){
	JsSample.get_stash_result(resp);
});

app.get('/no_client_route', {login_required: false, client_required: false}, function(req,resp){
  resp.send('no client required!');
});

app.post('/',{"rc_handler":"query"}, function(req,resp){
	var result = {'id':req.params};
	resp.send(result);
});