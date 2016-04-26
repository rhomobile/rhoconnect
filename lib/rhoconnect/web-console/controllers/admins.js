App.Controllers.Admins = Backbone.Router.extend({
		
    routes: {
      "login"      				   					: "login",
      "logout"     				   					: "logout",
	  ""	       				   					: "index",
	  "home"                       					: "index",
	  "sources/:id"	   								: "show_source_1",	
	  "sources/:id/:user_id/:doctype/:client_id"	: "show_source",
	  "doc/:dbkey/:source_id"      					: "get_doc",
	  "docselect"				   					: "server_doc",
	  "adapter"					   					: "adapter",
	  "users"					   					:  "users",
	  "users/new"			       					:  "new_user",
	  "user/:id"				   					:  "show_user",
	  "user/newping/:id"		   					:  "new_ping",
	  "users/newping"		   					    :  "new_ping_all",
	  "device/:device_id/:user_id" 					:  "user_device",
	  "stats"					  		  		    :  "stats"
    },
	        
    logout: function() {
	    var session = new Session();
        session.setAuthenticated(false);
	    session.setApiKey(null);
	    this.set_nav('info_home');
	    this.set_log('login');
		new App.Views.Index
    },
	
	index: function(){
		var session = new Session();
		var token = $('input#token').val();
		if(token){
			session.setAuthenticated(true);
			session.setApiKey(token);
			$('#nav_menu').css('display','none')
		}
		this.set_nav('info_home');
		if(session.getAuthenticated() == 'true'){
		    this.set_log('logout');
			new App.Views.Home({model: new Source(), model2: new Adapter()})
		}
		else
			new App.Views.Index
	},
	
	show_source_1: function(id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
		    source = new Source();
		    source.set("source_id",id);
			new App.Views.SourceDocs({model: source })
		}
		else
			new App.Views.Index
	},
	
	show_source: function(id,user,doctype,client_id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
		    source = new Source();
		    source.set("source_id",id);
			source.set("user_id",user);
			source.set("doctype",doctype);
			source.set('client_id',client_id)
			new App.Views.SourceDocs({model: source })
		}
		else
			new App.Views.Index
	},
	
	get_doc: function(dbkey,source_id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			doc = new Doc();
			doc.set("dbkey",dbkey);
			new App.Views.Doc({model: doc })
		}
		else
			new App.Views.Index
	},
		
	server_doc: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('server_doc');
			doc = new Doc();
			new App.Views.ServerDoc({model: doc })
		}
		else
			new App.Views.Index
	},
	
	adapter: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('adapter');
			adapter = new Adapter();
			new App.Views.SetAdapter({model: adapter })
		}
		else
			new App.Views.Index
	},
	
	users: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			user = new User();
			new App.Views.Users({model: user })
		}
		else
			new App.Views.Index
	},
	
	new_user: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			user = new User();
			new App.Views.NewUser({model: user })
		}
		else
			new App.Views.Index
	},
	
	show_user: function(id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			user = new User();
			user.set('name', id);
			new App.Views.ShowUser({model: user })
		}
		else
			new App.Views.Index
	},
	
	user_device: function(device_id,user_id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			client = new Client();
			client.set('device_id', device_id);
			client.set('user_id', user_id);
			new App.Views.ShowDevice({model: client })
		}
		else
			new App.Views.Index
	},
	
	new_ping: function(id){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			user = new User();
			user.set('name', id);
			new App.Views.NewPing({model: user })
		}
		else
			new App.Views.Index
	},
	
	new_ping_all: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			this.set_nav('users');
			user = new User();
			new App.Views.NewPing({model: user })
		}
		else
			new App.Views.Index
	},
	
	change_admin: function(){
		var session = new Session();
		if(session.getAuthenticated() == 'true'){
			this.set_log('logout');
			new App.Views.EditUser()
		}
		else
			new App.Views.Index
	},
	
	stats: function(){
		//hide route if stats not enabled
		if($("#stats").length > 0){
			var session = new Session();
			if(session.getAuthenticated() == 'true'){
				this.set_log('logout');
				this.set_nav('stats');
				stats = new Stats();
				new App.Views.Stats({model : stats})
			}
			else
				new App.Views.Index;
		}
	},
	
	set_nav: function(tab){
		$('#info_home').attr('class','');
		$('#server_doc').attr('class','');
		$('#users').attr('class','');
		$('#settings').attr('class','');
		$('#stats').attr('class','');
		$('#'+tab).attr('class','active');
	},
	
	set_log: function(state){
		if(state == 'login'){
			$('a#logout').css('display','none');
			$('a#login').css('display','block');
		}
		else{
			$('a#logout').css('display','block');
	    	$('a#login').css('display','none');
		}
	}
});