App.Views.Home = Backbone.View.extend({
	
	events: {
		"click a#reset"    : "reset",
		"click #app_url"   : "set_adapter",
		"submit form"      : "edit",
		"click #api_btn"   : "toggle_api_token"
	},
	
    initialize: function() {
 	    var domain = $('input#domain').val();
	    this.model.set('partition_type','app')
			this.model.fetch({
				error: function(model,resp)
				{
					if(resp.status == 422){
					 new App.Views.Index()
					}
				}
			});
      this.render(domain);
			this.options.model2.get_adapter();
    },  

    reset: function(){
	    var session = new Session();
		if(confirm("Are you sure you want to reset?")){
			session.reset();
		}
	},
	
	edit: function(e){
		e.preventDefault();
	    var session = new Session()
	    var password = $("#password2").val();
		$(".edituser-status")[0].firstChild.className = "label label-warning";
		$(".edituser-status")[0].firstChild.innerHTML = "loading...";
		$(".edituser-status").css("visibility","visible");
	  	$.ajax({
			type: 'PUT',
			url: '/rc/v1/users/' + 'rhoadmin',
			data: {attributes : {login : 'rhoadmin', password : password}},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(){
				//router.navigate("users", true);
				$(".edituser-status")[0].firstChild.className = "label label-success";
				$(".edituser-status")[0].firstChild.innerHTML = "success";
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$(".edituser-status")[0].firstChild.className = "label label-important";
				$(".edituser-status")[0].firstChild.innerHTML = "error";
				$('#home-alert')[0].innerHTML = resp.responseText;
		        $('#home-alert').css('display','block');
			}
		})
		return false;
	},
	
	set_adapter: function(e){
		e.preventDefault();
		var adapter_url = $('#input_adapter').val();
		//this.render();
		$(".setadapter-status")[0].firstChild.className = "label label-warning";
		$(".setadapter-status")[0].firstChild.innerHTML = "loading...";
		$(".setadapter-status").css("visibility","visible");
		this.delegateEvents();
		this.options.model2.set_adapter(adapter_url);
		return false;
	},
	
	toggle_api_token: function(e){
		e.preventDefault();
		if ($("#api_btn").attr("value") == "Show"){
			$("#api_token").css('display','inline');
			$("#api_btn").attr("value","Hide");
		}
		else {
			$("#api_token").css('display','none');
			$("#api_btn").attr("value","Show");
		}
	},
    
    render: function(domain) {
		session = new Session();
        $('#secondary-nav').css('display','block');
		out = "<div id='home-alert' class='alert alert-error' style='display:none'></div>"
		out += "<div class='alert alert-info' style='padding:10px 0 30px 0'>"
		out += "<div id='license' style='padding-left:5px' class='pull-left'></div>"
		out += "</div>";
		out += "<div class='span4' style='margin-left:0'>"
	    out += "<table id='source-table' class='table table-bordered'><thead><tr><th><h3>App partition sources</h3>";
	    out += "</th></tr></thead>"
		out += "</table></div>"
		
		out += "<table class='table table-bordered'>";
		out += "<tr><td><p style='margin-top:10px'>Sync Server</p></td>";
		out += "<td><p style='margin-top:10px'><code style='margin:0'>"+domain+"</code></p></td>";
		out += "<td><p style='margin-top:10px'>Paste this url into your client app configuration to sync with this RhoConnect instance.</p></td>"
		out += "</tr>"
		out += "<tr>"
		out += "<td width='20%'><p style='margin-top:10px'>Change Admin Password</p></td>"
		out += "<td width='40%'><form><p style='margin-top:10px'><input id='password2' type='password' name='password' value='' class='input-xlarge' placeholder='Enter new password' style='margin:0'/>"
		out += "<input type='submit' class='btn btn-primary' value='Save' style='margin-left:10px'/><div class='edituser-status' style='display:inline;margin-left:10px;visibility:hidden'><span class=''></span></div></p></form></td>"
		out += "<td width='40%'><p style='margin-top:10px'>By default the admin password is blank.</p></td>"
		out += "</tr>"
		out += "<tr>"
		out += "<td width='20%'><p style='margin-top:10px'>API Token</p></td>"
		out += "<td width='40%'><p id='api_token' style='margin-top:10px;display:none'><code>"+ session.getApiKey() +"</code></p>";
		out += "<input type='button' id='api_btn' class='btn' value='Show' style='display:inline;margin-left:10px'/></td>"
		out += "<td width='40%'><p style='margin-top:10px'>Include this token in all API calls made to RhoConnect.</p></td></tr>"
		out += "<tr>";
		out += "<td width='20%'><p style='margin-top:10px'>Backend App URL</p></td>";
	    out += "<td width='40%'><p style='margin-top:10px'><input id='input_adapter' type='text' name='adapter_url' value='' class='input-xlarge' placeholder='Enter URL' style='margin:0'/>";
	    out += "<input id='app_url' type='button' value='Save' class='btn btn-primary' style='margin-left:10px'/><div class='setadapter-status' style='display:inline;margin-left:10px;visibility:hidden'><span class=''></span></div></p></td>";
	    out += "<td width='40%'><p style='margin-top:10px'>If you are using <a href='http://docs.rhomobile.com/rhoconnect/plugin-intro' target='_blank'>RhoConnect Plugins</a>, you will need to ";
	    out += "define your backend app URL either here or in the plugin configuration.  For example, if you are using the rhoconnect-rb plugin in your rails app running locally, use the URL http://localhost:3000. <em><b>This needs to be set in order to use RhoConnect Plugins.</b></em></p></td>"
	    out += "</table>"
		out += "<p style='margin-top:10px'>*If Statistics is greyed out, it is not enabled in your config.ru file.  By default Rhoconnect apps will have this line <code>Rhoconnect::Server.enable  :stats</code> commented out. "
		out += "Older versions of RhoConnect will not have this line in the config.ru file at all.  Uncomment or add the line above to enable Statistics.  The Statistics tab will have different graphs to measure metrics/performance for RhoConnect.</p>"
		out += "</ol>"
		out += "<div class='pull-right'>"
		out += "<div class='reset-status' style='display:inline;'><span class='' style='margin-right:5px'></span></div>"
		out += "<a id='reset' class='btn btn-danger'>Reset</a>"
		out += "</div>"
        $(this.el).html(out);
        $('#main_content').html(this.el);
		return this
    }
});
