App.Views.Index = Backbone.View.extend({
	
	events: {
		"submit form" : "login"
	},
	
    initialize: function() {
        this.render();
    },

	login: function(e) {
		e.preventDefault();
		var login = $('#loginindex').val();
		var password = $("#password").val();
		$.ajax({
			type: 'POST',
			url: '/rc/v1/system/login',
			data: {login:login,password:password},
			success: function(resp){
				var session = new Session();
				session.setAuthenticated(true);
				session.setApiKey(resp);
				$('#login').css('display','inline');
				router.navigate('#home',true)
			},
			error: function(resp){
				if(resp.status == 422){
					new App.Views.Index()
				}
		        $('#home-alert').css('display','block');
				$('#home-alert')[0].innerHTML = resp.responseText;
			}
		})
	},

    render: function () {
   	    $('#secondary-nav').css('display','none');
		out  = "<div class='page-header well' style='margin-top:60px'><h1>Login</h1></div>";
		out += "<div id='home-alert' class='alert alert-error' style='display:none'></div>";
		out += "<form id='index-form'>";
	    out += "<table class='table table-bordered'>";
	    out += "<tr><td><input id='loginindex' type='text' name='login' class='input-xlarge' value='rhoadmin' placeholder='rhoadmin'/></td></tr>";
	    out += "<tr><td><input id='password' type='password' name='password' class='input-xlarge' value='' placeholder='Enter Password'/></td></tr>";
	    out += "<tr><td colspan=2><input type='submit' class='btn btn-primary' value='Login'/></td></tr>";
		out += "</table></form>";

        $(this.el).html(out);
        $('#main_content').html(this.el);  
    }
});
	
			
			
				
	
		
			
			
				
			
	
		
			
