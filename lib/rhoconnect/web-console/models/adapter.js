var Adapter = Backbone.Model.extend({
		
	defaults: {
		domain: null,
		backend_url: null,
		api_token: null
	},
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},
	
	set_adapter: function(adapter_url){
		var adapter_url = adapter_url;
		$.ajax({
			type: 'POST',
			url: '/rc/v1/system/appserver',
			data: {attributes : {'adapter_url' : adapter_url}},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(model, resp){
		  		$(".setadapter-status")[0].firstChild.className = "label label-success";
				$(".setadapter-status")[0].firstChild.innerHTML = "success";
				$('#input_adapter').val(adapter_url);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$(".setadapter-status")[0].firstChild.className = "label label-important";
				$(".setadapter-status")[0].firstChild.innerHTML = "error";
				$('#home-alert')[0].innerHTML = resp.responseText;
		        $('#home-alert').css('display','block');
			}
		})
	},
	
	get_adapter: function(){
		$.ajax({
			type: 'GET',
			url: '/rc/v1/system/appserver',
			beforeSend: function (HttpRequest) {
			     HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				if(resp != 'testtoken'){
					var r = JSON.parse(resp);
					if(r.adapter_url){
						$('#input_adapter').val(r.adapter_url);
					}
				}
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$(".setadapter-status")[0].firstChild.className = "label label-important";
				$(".setadapter-status")[0].firstChild.innerHTML = "error";
			}
		})
	}
	
});