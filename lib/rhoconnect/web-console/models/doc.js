var Doc = Backbone.Model.extend({
	
	defaults: {
		api_token: null,
		dockey: null,
		dbkey: null
	},
	
	initialize: function(){
		var session = new Session();
		this.set('api_token', session.getApiKey())
	},

	get_doc: function(dbkey,d_type){
		self = this;
		var session = new Session();
		this.set('dbkey',dbkey);
		$.ajax({
			type: 'GET',
			url: '/rc/v1/store/' + dbkey,
			beforeSend: function (HttpRequest) {
			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
			},
			success: function(resp){
				var data = ""
				r = self.formatJson(resp)
				if(resp != ''){
					data += "<tr><th colspan=3><h3 style='display:inline'>Data</h3><span class='pull-right'>" + 
							"<a id='clear' class='btn btn-danger'>clear document</a></span></th></tr>" +
							"<tr><td id='doc_data'><pre>" + r+ "</pre></td></tr>";
				}
				else{
					data += "<tr><th>Document is Empty</th></tr>";
				}
				$('tr.remove-tr-doc').remove();
				$('#docdata-table tr:last').after(data);
				if($(".query-status")[0] != undefined){
					$(".query-status")[0].firstChild.className = "label label-success";
					$(".query-status")[0].firstChild.innerHTML = "success";
				}
			},
			error: function(resp){
				if(resp.status == 422){
					 new App.Views.Index()
				}
				$('#docalert')[0].innerHTML = resp.responseText;
		        $('#docalert').css('display','block');
				$(".query-status")[0].firstChild.className = "label label-important";
				$(".query-status")[0].firstChild.innerHTML = "error";
			}
		})
	},
	
	formatJson: function(val) {
		var retval = '';
		var str = val;
		var pos = 0;
		var strLen = str.length;
		var indentStr = '&nbsp;&nbsp;&nbsp;&nbsp;';
		var newLine = '<br />';
		var char = '';


		for (var i=0; i<strLen; i++) {
		    char = str.substring(i,i+1);

		    if (char == '}' || char == ']') {
		        retval = retval + newLine;
		        pos = pos - 1;

		        for (var j=0; j<pos; j++) {

		            retval = retval + indentStr;

		        }

		    }

		    retval = retval + char;

		    if (char == '{' || char == '[' || char == ',') {
		        retval = retval + newLine;

		        if (char == '{' || char == '[') {
		            pos = pos + 1;
		        }

		        for (var k=0; k<pos; k++) {
		            retval = retval + indentStr;
		        }
		    }
		}

		return retval;

	}

	
})