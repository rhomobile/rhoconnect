var app = require('ballroom');
var rc_helpers = require('rhoconnect_helpers');

app.controllerName('Sample2');
app.defaults({admin_required:false,login_required:true,source_required:true,client_required:true});

app.get('/',{"rc_handler":"query"}, function(req,resp){
	var result = {'1':{'name':'iPhone'}};
	resp.send(result);
});

app.get('/error_throw',{},function(req,resp){
	throw "Error in function";
});

//json['args'] = {:product => {:name=>foo,:price=>bar}}
app.post('/',{}, function(req,resp){
	var result = {'id':req.params};
	resp.send(result);
});

//json['args'] = {:id=>1,:product => {:name=>foo,:price=>bar}}
app.put('/:id',{}, function(req,resp){
	var result =  {'id':req.params};
	resp.send(result);
});

//json['args'] = {:id => 2}
app.del('/:id',{}, function(req,resp){
	var result =  {'id':req.params};
	resp.send(result);
});