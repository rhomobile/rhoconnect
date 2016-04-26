var Client = Backbone.Model.extend({
	
	defaults: {
		api_token: null,
		client_id: null
	},
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},
		
	get_clients: function(user_id){
		var session = new Session();
		$.ajax({
			type: 'get',
			url: '/rc/v1/users/' + user_id + '/clients',
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				data = ""
				$.each(r,function(index,value){
					data += "<tr><td><a href='#device/"+value+"/"+user_id+"'>"+value+"</a></td></tr>";
				})
				$('tr.remove-tr-device').remove();
				$('#device-table tr:last').after(data);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#showuser-alert')[0].innerHTML = resp.responseText;
		        $('#showuser-alert').css('display','block');
			}
		})
	},
	
	list_client_docs: function(client_id,source_id){
		var session = new Session();
		$.ajax({
			type: 'GET',
			url: '/rc/v1/clients/' + client_id + '/sources/' + source_id + '/docnames',
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				data = ""
				$.each(r,function(index,value){
					data += "<tr><td colspan='2'><a href='#doc/"+value+"/source_id="+source_id+"'>"+value+"</a></td></tr>";
				})
				$('tr.remove-tr-docs').remove();
				$('#sourcedocs-table tr:last').after(data);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#showdevice-alert')[0].innerHTML = resp.responseText;
		        $('#showdevice-alert').css('display','block');
			}
		})
	},
	
	get_client_params: function(client_id){
		var session = new Session();
		$.ajax({
			type: 'GET',
			url: '/rc/v1/clients/' + client_id,
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				data = "";
				$.each(r, function(index,value){
					if(value.value != null && value.value != "")
						data += "<tr><td width='25%'>" + value.name + "</td><td>" + value.value + "</td></tr>"
				})
				$('tr.remove-tr-client').remove();
				$('#deviceattr-table tr:last').after(data);
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
})
