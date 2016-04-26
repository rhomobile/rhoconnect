App.Views.ShowDevice = Backbone.View.extend({
	
	events: {
		"click a#delete-device" : "delete_device",
	},
	
    initialize: function() {
	    var device_id = this.model.get('device_id');
		this.render(device_id);
		this.model.get_client_params(device_id);
		//this.model.list_client_docs(device_id,'Product');
		source = new Source();
		source.set('partition_type','all');
		source.set('user_id',this.model.get('user_id'));
	    source.set('client_id',device_id);
		source.set('doctype','client');
		source.fetch();
    },

	delete_device: function() {
		if(confirm("Are you sure you want to delete this device?")){
		    var user_id = this.model.get('user_id');
		 	var client_id = this.model.get('device_id');
			var token = this.model.get('api_token')
			$.ajax({
				type: 'DELETE',
				url: '	/rc/v1/users/' + user_id + '/clients/' + client_id,
				beforeSend: function (HttpRequest) {
				            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", token);
				},
				success: function(resp){
					router.navigate("user/"+user_id,true)
				},
				error: function(resp){
					if(resp.status == 422){
						 new App.Views.Index()
					}
					$('#showdevice-alert')[0].innerHTML = resp.responseText;
			        $('#showdevice-alert').css('display','block');
				}
			})
		}
	},
    
    render: function(device_id) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><span style='font-size:24px;line-height:36px;font-weight:bold'>Device: "+device_id+"</span>";
		out += "<span class='pull-right'><a id='delete-device' class='btn btn-danger'>Delete Device</a></span></div>";
		out += "<div id='showdevice-alert' class='alert alert-error' style='display:none'></div>";
	    out += "<table id='deviceattr-table' class='table table-bordered'>";
	    out += "<tr><th><h3>Attributes</h3></th></tr>";
	    out += "<tr class='remove-tr-client'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
	    out += "</table>";
		out += "<table id='source-table' class='table table-bordered'><tr><th><h3>Sources for device</h3></th></tr>";
		out += "<tr class='remove-tr-user'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
		out += "</table>"
	   
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});