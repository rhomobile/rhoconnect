App.Views.Doc = Backbone.View.extend({
	events: {
		"click a#clear"	: "clear"
	},
	
    initialize: function() {
		var dbkey = this.model.get('dbkey');
		this.render(dbkey);
		this.model.get_doc(dbkey,'none');
    },

	clear: function(e){
		e.preventDefault();
		dbkey = this.model.get('dbkey');
		var dt   = 'hash';
		var data = [];
		token = this.model.get('api_token');
 		if(dbkey.search(/token/i) > 0 || dbkey.search(/size/i) > 0){
			data = '';
		}
		var self = this;
		$.ajax({
			type: 'POST',
			url: '/rc/v1/store/' + dbkey,
			data: {data : data},
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
				$('#docalert')[0].innerHTML = resp.responseText;
		        $('#docalert').css('display','block');
			}
		})
	},

    
    render: function(dbkey) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><h2>Document&nbsp;"+dbkey+"</h2></div>";
		out += "<div id='docalert' class='alert alert-error' style='display:none'></div>";
		out += "<table id='docdata-table' class='table table-bordered'><tr></tr>";
		out += "<tr class='remove-tr-doc'><td colspan='2' style='text-align:center'>Loading...</td></tr>"
		out += "</table>"
		
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});