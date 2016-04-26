var Source = Backbone.Model.extend({
	
	defaults: {
		api_token: null,
		rhoconnect_version: null,
		seats: null,
		issued: null,
		source_id: null,
		partition_type: null,
		user_id: null,
		doctype: null,
		device_id: null
	},
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},
	
    methodUrl: {
	  'read'  : '/rc/v1/sources/type/'
    },

    sync: function(method, model, options) {
      if (model.methodUrl && model.methodUrl[method.toLowerCase()]) {
        options = options || {};
        options.url = model.methodUrl[method.toLowerCase()];
		options.url += this.get('partition_type')
		options.token = this.get('api_token')
      }
      Backbone.sync(method, model, options);
    },
	
	parse: function(resp){
		var user 		= this.get('user_id');
		var doctype 	= this.get('doctype');
		var client_id 	= this.get('client_id');
		var adapters = "";
		$.each(resp, function(index,value){
			if(doctype == null){
				adapters += "<tr><td colspan='2'><a href='#sources/"+value+"'>"+ value + "</a></td></tr>"
			}
			else{
				adapters += "<tr><td colspan='2'><a href='#sources/"+value+"/"+user+"/"+doctype+"/"+client_id+"'>"+ value + "</a></td></tr>"
			}
		})
		$('tr.remove-tr-user').remove();
		$('#source-table tr:last').after(adapters);
	},

	list_source_docs: function(source_id,user_id){
		var session = new Session();
		$.ajax({
			type: 'GET',
			url: '/rc/v1/users/' + user_id + '/sources/' + source_id + '/docnames',
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				var docs = "";
				$.each(r, function(index,value){
					docs += "<tr><td width='25%'>" + index + "</td><td><a href='#doc/"+value+"/source_id="+source_id+"'>" + value + "</a></td></tr>"
				})
				$('tr.remove-tr-docs').remove();
				$('#sourcedocs-table tr:last').after(docs);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#docalert')[0].innerHTML = resp.responseText;
		        $('#docalert').css('display','block');
			}
		})
	},
	
	get_source_params: function(source_id,user_id){
		var session = new Session();
		$.ajax({
			type: 'GET',
			url: '/rc/v1/sources/' + source_id,
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var r = JSON.parse(resp)
				var params = "";
				$.each(r, function(index,value){
					if(value.value != null && value.value != "")
						params += "<tr><td width='25%'>" + value.name + "</td><td>" + value.value + "</td></tr>"
				})
				$('tr.remove-tr-src').remove();
				$('#sourceparams-table tr:last').after(params);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#docalert')[0].innerHTML = resp.responseText;
		        $('#docalert').css('display','block');
			}
		})
	}
	
})