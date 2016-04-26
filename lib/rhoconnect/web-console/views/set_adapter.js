App.Views.SetAdapter = Backbone.View.extend({
	
	events: {
		"submit form" : "set_adapter"
	},
	
    initialize: function() {
	    this.render()
		this.model.get_adapter();
    },

	set_adapter: function(e){
		e.preventDefault();
		var adapter_url = $('#input_adapter').val();
		this.render(adapter_url);
		$(".setadapter-status")[0].firstChild.className = "label label-warning";
		$(".setadapter-status")[0].firstChild.innerHTML = "loading...";
		$(".setadapter-status").css("visibility","visible");
		this.delegateEvents();
		this.model.set_adapter(adapter_url);
	},
	
    render: function() {
        $('#secondary-nav').css('display','block');
		out  = "<h3>Backend App URL</h3>";
	    out += "<form style='margin:0'>";
	    out += "<input id='input_adapter' type='text' name='adapter_url' value='' class='input-xlarge' placeholder='Enter Adapter URL' style='margin:0'/>";
	    out += "<input type='submit' value='Submit' class='btn btn-primary' style='margin-left:10px'/><div class='setadapter-status' style='display:inline;margin-left:10px;visibility:hidden'><span class=''></span></div>";
	    out += "</form>";
	
        $(this.el).html(out);
        $('#settings_main').html(this.el);
    }
});



