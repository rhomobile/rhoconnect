App.Views.ServerDoc = Backbone.View.extend({
	
	events: {
		"submit form#string_s"    : "upload_string",
		"submit form#db_key_form" : "query",
		"click a#clear"			  : "clear"
	},
	
    initialize: function(dbkey) {
		this.render("");
    },

	clear: function(e){
		e.preventDefault();
		dbkey = this.model.get('dbkey');
		token = this.model.get('api_token')
		var self = this;
		$.ajax({
			type: 'POST',
			url: '/rc/v1/store/' + dbkey,
			data: {data : ''},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", token);
			},
			success: function(){
				data = "<tr><th colspan=3><h3 style='display:inline'>Data</h3><div class='pull-right'>" + 
						"<a class='btn btn-danger'>clear document</a></div></th></tr>" +
						"<tr><td></td></tr>";
				$('#docdata-table').find("tr:gt(0)").remove();
				$('#docdata-table tr:last').after(data);
				self.delegateEvents();
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#doc-alert')[0].innerHTML = resp.responseText;
		        $('#doc-alert').css('display','block');
			}
		})
	},

	upload_string: function(e){
		e.preventDefault();
		var self = this;
		$(".upload-status")[0].firstChild.className = "label label-warning";
		$(".upload-status")[0].firstChild.innerHTML = "loading...";
		$(".upload-status").css("visibility","visible");
		var doc = $('#input_key').val();
		var data = $("#data").val();
		token = this.model.get('api_token');
		$.ajax({
			type: 'POST',
			url: '/rc/v1/store/' + doc,
			data: {data : data},
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", token);
			},
			success: function(){
				$(".upload-status")[0].firstChild.className = "label label-success";
				$(".upload-status")[0].firstChild.innerHTML = "success";
				
				data = "<tr><th colspan=3><h3 style='display:inline'>Data</h3><div class='pull-right'>" + 
						"<a id='clear' class='btn btn-danger'>clear document</a></div></th></tr>" +
						"<tr><td id='doc_data'>" + data+ "</td></tr>";
				$('#docdata-table').find("tr:gt(0)").remove();
				$('#docdata-table tr:last').after(data);
				self.delegateEvents();
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$(".upload-status")[0].firstChild.className = "label label-danger";
				$(".upload-status")[0].firstChild.innerHTML = "error";
				$('#doc-alert')[0].innerHTML = resp.responseText;
		        $('#doc-alert').css('display','block');
			}
		})
	},

	query: function(e){
		e.preventDefault();
		var dbkey = $('#input_key').val();
		this.render(dbkey);
		$(".query-status")[0].firstChild.className = "label label-warning";
		$(".query-status")[0].firstChild.innerHTML = "loading...";
		$(".query-status").css("visibility","visible");
		this.model.get_doc(dbkey,'string');
		this.delegateEvents();
	},
    
    render: function(dbkey) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><h2>Document&nbsp;"+dbkey+"</h2>";
		out += "<p>Enter a document key to view the stored values in redis.  You can also set and delete data here.</p></div>"
		out += "<div id='docalert' class='alert alert-error' style='display:none'></div>";
		
	    out += "<form id='db_key_form' class='form-horizontal'>";
	    out += "<input id='input_key' type='text' name='dbkey' value='"+dbkey+"' class='input-xlarge' placeholder='Enter document key'/>";
	    out += "<input type='submit' value='Submit' class='btn btn-primary' style='margin-left:10px'><div class='query-status' style='display:inline;margin-left:10px;visibility:hidden'><span class=''></span></div>";
	    out += "</form>";
	    if(dbkey != ""){
			out += "<form id='string_s' class='form-horizontal'>";
			out += "<input id='data' type='text' name='data' value='' class='input-xlarge' placeholder='Enter document value'/>";
			out += "<input type='submit' value='Submit' class='btn btn-primary' style='margin-left:10px'><div class='upload-status' style='display:inline;margin-left:10px;visibility:hidden'><span class=''></span></div>";
			out += "</form>";
			out += "<table id='docdata-table' class='table table-bordered'><tr></tr></table>";
		}
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});