App.Views.Users = Backbone.View.extend({
	
    initialize: function() {
		this.render();
		this.model.get_users('user_table');
    },
    
    render: function() {
        $('#secondary-nav').css('display','block');
		out = "<div id='ping-alert' class='alert alert-error' style='display:none'></div>";
	    out += "<table id='users_table' class='table table-bordered'>";
	    out += "<tr><th><div style='display:inline;font-size:18px'>Registered Users<div class='pull-right'><a href='#users/new' class='btn btn-primary'>Create User</a>";
	    out += "<a href='#users/newping' class='btn btn-primary' style='margin-left:10px'>Ping Users</a></div></th></tr>";
	    out += "<tr class='remove-tr-users'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
	    out += "</table></form>";
	   
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});