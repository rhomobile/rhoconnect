var Stats = Backbone.Model.extend({
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},
	
	get_sources: function(){
		session = new Session();
	    $.ajax({
			type: 'GET',
			url: 'get_sources',
			data: {api_token : session.getApiKey()},
			success: function(resp){
				r = JSON.parse(resp)
				var list  = "";
				var list2 = "";
				$.each(r, function(index,value){
					list  += "<div class='accordion-inner'><a id='"+value+"' class='http_timing'>- "+value+"</a></div>";
					list2 += "<div class='accordion-inner'><a id='"+value+"m' class='source_timing_display'>- "+value+"</a></div>";
				})
				$("#collapseTwo").append(list);
				$("#collapseThree").append(list2);
			},
			error: function(resp){
				$("#collapseTwo").after("<li>No Adapters Available</li>")
				$("#collapseThree").after("<li>No Adapters Available</li>")
			}
		})
	},
	
	get_http_routes: function(){
		session = new Session();
	    $.ajax({
			type: 'GET',
			url: 'get_http_routes',
			data: {api_token : session.getApiKey()},
			success: function(resp){
				r = JSON.parse(resp)
				var list  = "";
				$.each(r, function(index,value){
					value
					list  += "<div class='accordion-inner'><a id='"+value+"' class='http_timing_key'>- "+value+"</a></div>";
				})
				$("#collapseFour").append(list);
			},
			error: function(resp){
				$("#collapseFour").after("<li>No Routes Available</li>")
			}
		})
	},
		
	user_stats: function(){
		session = new Session();
	    $.ajax({
			type: 'POST',
			url: 'get_user_graph',
			data: {api_token : session.getApiKey()},
			success: function(resp){
				$('#stats_main').html(resp);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#stats-alert')[0].innerHTML = resp.responseText;
		        $('#stats-alert').css('display','block');
			}
		})
	},
	
	device_count: function(){
		session = new Session();
	    $.ajax({
			type: 'POST',
			url: 'device_count',
			data: {api_token : session.getApiKey()},
			success: function(resp){
				$('#stats_main').html(resp);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#stats-alert')[0].innerHTML = resp.responseText;
		        $('#stats-alert').css('display','block');
			}
		})
	},
	
	source_timing: function(display_name,key){
		session = new Session();
	    $.ajax({
			type: 'POST',
			url: 'source_timing',
			data: {api_token : session.getApiKey(),display_name : display_name, key : key},
			success: function(resp){
				$('#stats_main').html(resp);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#stats-alert')[0].innerHTML = "No Data Available";
		        $('#stats-alert').css('display','block');
			}
		})
	},
	
	http_timing: function(display_name){
		session = new Session();
	    $.ajax({
			type: 'POST',
			url: 'http_timing',
			data: {api_token : session.getApiKey(),display_name : display_name},
			success: function(resp){
				$('#stats_main').html(resp);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#stats-alert')[0].innerHTML = "No Data Available";
		        $('#stats-alert').css('display','block');
			}
		})
	},
	
	http_timing_key: function(display_name){
		session = new Session();
	    $.ajax({
			type: 'POST',
			url: 'http_timing_key',
			data: {api_token : session.getApiKey(),display_name : display_name},
			success: function(resp){
				$('#stats_main').html(resp);
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#stats-alert')[0].innerHTML = "No Data Available";
		        $('#stats-alert').css('display','block');
			}
		})
	}
	
})
