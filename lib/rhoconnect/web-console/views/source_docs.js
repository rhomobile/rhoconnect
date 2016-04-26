App.Views.SourceDocs = Backbone.View.extend({
	
    initialize: function() {
		var source_id = this.model.get('source_id');
		var user	  = this.model.get('user_id');
		var doctype   = this.model.get('doctype');
		var client_id = this.model.get('client_id');
		this.render(source_id);
		this.model.get_source_params(source_id);
		if(doctype == 'client'){
			client = new Client();
			client.list_client_docs(client_id,source_id)
		}
		else{
			this.model.list_source_docs(source_id,user);
		}
    },  	
    
    render: function(source_id) {
        $('#secondary-nav').css('display','block');
		out  = "<div class='page-header'><h1>"+source_id+"</h1></div>";
		out += "<div class='docalert alert-error' style='display:none'></div>";
	    out += "<table id='sourceparams-table' class='table table-bordered'><thead><tr><th><h3>Attributes</h3></th>";
	    out += "<td>Attributes for source adapter. <a href='http://docs.rhomobile.com/rhoconnect/source-adapters' target='_blank'>Read more</a></td></tr></thead>"
	    out += "<tr class='remove-tr-src'><td colspan='2' style='text-align:center'>Loading...</td></tr>";
		out += "</table>";
	    out += "<table id='sourcedocs-table' class='table table-bordered'><tr><th class='span5'><h3>Documents</h3></th><td>Redis documents for source adapter. <a href='http://docs.rhomobile.com/rhoconnect/source-adapters#data-partitioning' target='_blank'>Read more</a></td></tr>";
	    out += "<tr class='remove-tr-docs'><td colspan='2' style='text-align:center'>Loading...</td></tr>";
	    out += "</table>";
        $(this.el).html(out);
        $('#main_content').html(this.el);
    }
});