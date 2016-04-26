var User = Backbone.Model.extend({
	
	defaults: {
		api_token: null,
		name: null
	},
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},
	
	get_users: function(tble_name){
		var session = new Session();
		var tble_name = tble_name;
		$.ajax({
			type: 'GET',
			url: '/rc/v1/users',
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				data = ""
				names = "";
				count = r.length;
				$.each(r,function(index,value){
					data += "<tr><td colspan='3'><a href='#user/"+value+"'>"+value+"</a></td></tr>";
					names += value;
					if(index + 1 < count)
						names += ",";
				})
				if(tble_name == 'ping')
					$('#pinguser').val(names);
				else
				    $('tr.remove-tr-users').remove();
					$('#users_table tr:last').after(data);
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
	
	create_user: function(){
		var login = $('#new-login').val();
	    var password = $('#new-password').val();
	    var session = new Session();
		$.ajax({
			type: 'POST',
			url: '/rc/v1/users',
			data: {attributes : {login : login, password : password}},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				router.navigate("users", true);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#newuser-alert')[0].innerHTML = resp.responseText;
		        $('#newuser-alert').css('display','block');
			}
		})
	},
	
	delete_user: function(){
		var session = new Session();
		if(confirm("Are you sure you want to delete this user?")){
			$.ajax({
				type: 'DELETE',
				url: '/rc/v1/users/' + this.get('name'),
				beforeSend: function (HttpRequest) {
				            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
				},
				success: function(resp){
					router.navigate("users", true);
				},
				error: function(resp){
					if(resp.status == 422){
						 new App.Views.Index()
					}
					$('#newuser-alert')[0].innerHTML = resp.responseText;
			        $('#newuser-alert').css('display','block');
				}
			})
		}
		
	},
	
	new_ping: function(){
		var session = new Session();
		$.ajax({
			type: 'GET',
			url: '/rc/v1/sources/type/user',
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp);
				source_list = "";
				var count = r.length;
				$.each(r, function(index,value){
					source_list += value;
					if(index + 1 < count)
						source_list += ",";
				})
				$('input#sources').val(source_list);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#newuser-alert')[0].innerHTML = resp.responseText;
		        $('#newuser-alert').css('display','block');
			}
		})
	}
})