App.Views.NewUser = Backbone.View.extend({
	
	events: {
		"submit form" : "create_user"
	},
	
    initialize: function() {
		this.render();
    },

    create_user: function(e) {
		e.preventDefault();
		this.model.create_user();
	},
    
    render: function() {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><h2>New user</h2></div>";
		out += "<div id='newuser-alert' class='alert alert-error' style='display:none'></div>";
		out += "<form>"
	    out += "<input id='new-login' type='text' name='login' placeholder='login' style='margin:0'/>";
		out += "<input id='new-password' type='password' name='password' placeholder='password' style='margin:0 0 0 10px'/>";
		out += "<input type='submit' class='btn btn-primary' value='Add' style='margin:0 0 0 10px'/>"
	    out += "</form>";
	   
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});