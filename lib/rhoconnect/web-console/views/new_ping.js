App.Views.NewPing = Backbone.View.extend({

	events:{
		"submit form" : "ping"
	},

    initialize: function() {
	    var name = this.model.get('name');
		this.render(name);
		this.model.new_ping(name);
		if(name == undefined)
			this.model.get_users('ping');
    },

	ping: function(e) {
		e.preventDefault();
		var users = $('#pinguser').val().split(',');
		var message = $('#pingmessage').val();
		var vibrate = $('#pingvibrate').val();
		var sound = $('#pingsound').val();
		var badge = $('#pingbadge').val();
		var sources = $('#sources').val();
		if(sources.length > 0) {
			sources = sources.split(',');
		} else {
			sources = [];
		}
		var token = this.model.get('api_token');
		$.ajax({
			type: 'POST',
			url: '/rc/v1/users/ping',
			data: {
				user_id : users,
				message : message,
				vibrate : vibrate,
				sound   : sound,
				badge   : badge,
				sources : sources
			},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", token);
			},
			success: function(){
				router.navigate("users", true);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#ping-alert')[0].innerHTML = resp.responseText;
		        $('#ping-alert').css('display','block');
			}
		})
	},

    render: function(name) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><h2>Ping User/s</h2></div>";
		out += "<div id='ping-alert' class='alert alert-error' style='display:none'></div>";
	    out += "<form><table id='users_table' class='table table-bordered'>";
	    out += "<input id='pinguser' type='hidden' name='user_id' value='"+name+"' class='input-xlarge' />";
	    out += "<tr><td>Message:</td><td><input id='pingmessage' type='text' name='message' value='push message' class='input-xlarge' /></td>";
	    out += "<td>Message to be displayed in push notification</td></tr>"
	    out += "<tr><td>Sources</td><td><input type='text' name='sources' id='sources' value='' class='input-xlarge'/></td>";
	    out += "<td>List of sources to be synchronized</td></tr>"
		out += "<tr><td>Sound</td><td><input id='pingsound' type='text' name='sound' value='welcome.mp3' class='input-medium'/></td>";
		out += "<td>allows you to play audio file if it exists on client</td></tr>"
		out += "<tr><td>Badge</td><td><input id='pingbadge' type='text' name='badge' value='1' class='input-small'/></td>";
		out += "<td>Number displayed on device next to app when push notification arrives. Available for iPhone</td></tr>"
		out += "<tr><td>Vibrate</td><td><input id='pingvibrate' type='text' name='vibrate' value='2000' class='input-small'/>&nbsp;(milliseconds)</td>"
		out += "<td>Duration of vibration when push notification is received</td></tr>"
	    out += "<tr><td colspan=3><input type='submit' class='btn btn-primary' value='Ping!' /></td></tr>"
	    out += "</table></form>";

        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});