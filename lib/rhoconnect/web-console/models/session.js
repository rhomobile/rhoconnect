var Session = Backbone.Model.extend({
		
    setApiKey: function(apiKey) {
        window.sessionStorage.setItem('apiKey', apiKey)
    },	

    setAuthenticated: function(value) {
		window.sessionStorage.setItem('authenticated', value)
	},
	
	getApiKey: function() {
        return window.sessionStorage.getItem('apiKey')
    },	

    getAuthenticated: function() {
		return window.sessionStorage.getItem('authenticated')
	},
	
	reset: function() {
		$(".reset-status")[0].firstChild.className = "label label-warning";
		$(".reset-status")[0].firstChild.innerHTML = "loading...";
		$(".reset-status").css("visibility","visible");
		var token = this.getApiKey();
		$.ajax({
			type: 'POST',
			url: '/rc/v1/system/reset',
			beforeSend: function (XMLHttpRequest) {
			    XMLHttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", token);
			},
			success: function(){
				$(".reset-status")[0].firstChild.className = "label label-success";
				$(".reset-status")[0].firstChild.innerHTML = "success";
				//router.navigate("#", true);
			},
			error: function(resp){
				$(".reset-status")[0].firstChild.className = "label label-danger";
				$(".reset-status")[0].firstChild.innerHTML = "error";
				$('#home-alert')[0].innerHTML = resp.responseText;
		        $('#home-alert').css('display','block');
			}
		})
	}
});