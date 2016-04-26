App.Views.Stats = Backbone.View.extend({
	
	events: {
		"click a#user_count"    		: "user_count",
		"click a#device_count"  		: "device_count",
		"click a.http_timing"   		: "http_timing",
		"click a.http_timing_key"       : "http_timing_key",
		"click a.source_timing_display" : "source_timing_display",
		"click a.source_timing_key"     : "source_timing_key",
		
	},
	
	initialize: function(){
		this.render();
		this.user_count();
		this.model.get_sources();
		this.model.get_http_routes();
	},
	
	user_count: function(){
		$("#device_count").attr('class','');
		$('#user_count').attr('class','label label-info');
		this.model.user_stats();
	},

    device_count: function(){
	$('#stats_main').html("<i>Loading...</i>")
		$("#user_count").attr('class','');
		$('#device_count').attr('class','label label-info');
		this.model.device_count();
	},
	
	http_timing: function(ev){
		$('#stats_main').html("<i>Loading...</i>")
		var display_name = ev.currentTarget.id;
		$('.http_timing').attr('class','http_timing');
		ev.currentTarget.className = "http_timing label label-info"
		this.model.http_timing(display_name);
	},
	
	http_timing_key: function(ev){
		$('#stats_main').html("<i>Loading...</i>")
		var display_name = ev.currentTarget.id;
		$('.http_timing_key').attr('class','http_timing_key');
		ev.currentTarget.className = "http_timing_key label label-info"
		this.model.http_timing_key(display_name);
	},
	
	source_timing_display: function(ev){
		$('#stats_main').html("<i>Loading...</i>")
		var display_name = ev.currentTarget.id;
		
		$(".source_timing_display").attr('class','source_timing_display');
		$('#'+display_name).attr('class','label label-info source_timing_display');
		this.model.source_timing(display_name.substr(0,display_name.length - 1));	
	},
	
	source_timing_key: function(ev){
		var display_name = ev.currentTarget.id;
		var key = ev.currentTarget.innerHTML;
		
		$(".source_timing_key").attr('class','source_timing_key');
		$('#'+key).attr('class','label label-info source_timing_key');
		this.model.source_timing(display_name,key);	
	},
	
	change_tab: function(tab){
	//	$(".label").attr('class','');
	//	$('#'+tab).attr('class','label label-info');
	},
	
	render: function(){
		$('#secondary-nav').css('display','block');
		out = "<div id='stats-alert' class='alert alert-error' style='display:none'></div>"
		out += "<div class='span4'>"
		out += "<div class='accordion' id='accordion2'>"
		out += "<div class='accordion-group'><div class='accordion-heading' style='font-weight:bold'>"
		out += "<a class='accordion-toggle' data-toggle='collapse' data-parent='#accordion2' href='#collapseOne'>Count</a></div>"
		out += "<div id='collapseOne' class='accordion-body in collapse'>";
		out += "<div class='accordion-inner'><a id='device_count'>- Device Count</a></div>"
		out += "<div class='accordion-inner'><a class='label label-info' id='user_count'>- User Count</a></div>"
		out += "</div></div>"
		
		out += "<div class='accordion-group'>"
		out += "<div class='accordion-heading' style='font-weight:bold'>"
		out += "<a class='accordion-toggle' data-toggle='collapse' data-parent='#accordion2' href='#collapseTwo'>HTTP Adapter Timing</a></div>"
		out += "<div id='collapseTwo' class='accordion-body collapse'>";
		out += "</div></div>"
		
		out += "<div class='accordion-group'>"
		out += "<div class='accordion-heading' style='font-weight:bold'>"
		out += "<a class='accordion-toggle' data-toggle='collapse' data-parent='#accordion2' href='#collapseFour'>HTTP Route Timing</a></div>"
		out += "<div id='collapseFour' class='accordion-body collapse'>";
		out += "</div></div>"
		
		out += "<div class='accordion-group'>"
		out += "<div class='accordion-heading' style='font-weight:bold'>"
		out += "<a class='accordion-toggle' data-toggle='collapse' data-parent='#accordion2' href='#collapseThree'>Source Timing</a></div>"
		out += "<div id='collapseThree' class='accordion-body collapse'>";
		out += "</div></div>"
		
		out += "</div></div>"
		
		//out += "<li id='http_timing_header' class='nav nav-header'>Adapter HTTP Timing</li>"
		//out += "<li><a id='http_timing'>HTTP Timing</a></li>"
		//out += "<li class='nav nav-header'>Source Timing</li>"
		//out += "<li><a id='source_timing'>Source Timing</a></li>"
		//out += "</ul>"
		out += "<div id='stats_main' style='margin-left:365px'>"
		out += "</div>"
		//out += "<ul id='source-list' class='nav nav-pills' style='margin-left:200px'></ul>"
		out += "</div></div>"
				
        $(this.el).html(out);
        $('#main_content').html(this.el);
	}
})