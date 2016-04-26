App.Views.ShowUser = Backbone.View.extend({
	
	events: {
		"click a#delete-user" : "delete_user",
	},
	
    initialize: function() {
	    var name = this.model.get('name');
		this.render(name);
		client = new Client();
		client.get_clients(name);
		source = new Source();
		source.set('partition_type','all');
		source.set('user_id',name);
		source.set('doctype','source');
		source.fetch();
    },

    delete_user: function(e) {
		e.preventDefault();
		this.model.delete_user();
	},
    
    render: function(name) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><div style='font-size:24px;font-weight:bold;display:inline'>User: "+name+"</div><div class='pull-right' style='display:inline'>";
		out += "<a id='delete-user' class='btn btn-danger'>Delete User</a><a href='#user/newping/"+name+"' class='btn' style='margin-left:10px'>Ping User</a></div></div>";
		out += "<div id='showuser-alert' class='alert alert-error' style='display:none'></div>";
	    out += "<table id='source-table' class='table table-bordered'>";
	    out += "<tr><th><h3>Sources</h3></th></tr>";
	    out += "<tr class='remove-tr-user'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
	    out += "</table>";
		out += "<table id='device-table' class='table table-bordered'><tr><th><h3>Registered Devices</h3></th></tr>";
		out += "<tr class='remove-tr-device'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
		out += "</table>"
	   
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});
