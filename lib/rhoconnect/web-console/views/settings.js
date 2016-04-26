// App.Views.Settings = Backbone.View.extend({
// 	
// 	events: {
// 		"click a#change_admin" : "change_admin",
// 		"click a#api_token"   : "api_token",
// 		"click a#backend_app" : "backend_app"
// 	},
// 	
//     initialize: function() {
//         this.render();
// 		new App.Views.EditUser()
//     },  
// 
// 	change_admin: function(){
// 		this.change_tab('change_admin')
// 		new App.Views.EditUser()
// 	},
// 
//     api_token: function(){
// 	this.change_tab('api_token')
// 		new App.Views.ApiToken()
// 	},
// 	
// 	backend_app: function(){
// 		this.change_tab('backend_app')
// 		adapter = new Adapter();
// 		new App.Views.SetAdapter({model: adapter })
// 	},
// 	
// 	change_tab: function(tab){
// 		$('#change_admin').parent().attr('class','');
// 		$('#api_token').parent().attr('class','');
// 		$('#backend_app').parent().attr('class','');
// 		$('#'+tab).parent().attr('class','active');
// 	},
//     
//     render: function() {
//         $('#secondary-nav').css('display','block');
// 		out = "<div id='settings-alert' class='alert alert-error' style='display:none'></div>"
// 		out += "<div class='tabs-left'><ul class='nav nav-tabs'>"
// 		out += "<li class='active'><a id='change_admin'>Change Admin Password</a></li>"
// 		out += "<li><a id='api_token'>API Token</a></li>"
// 		out += "<li><a id='backend_app'>Plugin Settings</a></li>"
// 		out += "</ul>"
// 		out += "<div id='settings_main'>"
// 		out += "</div>"
// 		out += "</div></div>"
// 				
//         $(this.el).html(out);
//         $('#main_content').html(this.el);
// 		return this
//     }
// });
