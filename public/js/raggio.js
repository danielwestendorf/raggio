function shorten(element) { //function to shorten the content of the comment if it is too long. Add it to the title attribute if it is
	var html = $(element).html();
	if (html.length > 30) {
		shortened =html.substring(0, 30)
		$(element).html(shortened + "...");
		$(element).attr("title", html);
	}
}

function showRows(selector) {
	$(selector).first().fadeIn().removeClass('hidden');
	if ($(selector).length > 0){setTimeout("showRows('"+selector+"')", 250)}
}

function getStales() {
	$('#stales tbody:last').html("Loading...");
	$.ajax({
		type: "GET",
		dataType: 'json',
		url	: "/stale",
		data: "stale_cutoff=" + $('#staleForm input[type="text"]').val(),
		success: function(json) {
			table = $('#stales tbody:last')
			table.html(' ');
			if ($(json).length < 1) {table.append('<tr><td></td><td><b>No Stale Records Found</b></td><td></td><td></td></tr>')}
			$(json).each(function() {
				date = Date.parse(this.acctstarttime.split("T").join(" ").substring(0,19)).toString('MM/d/yyyy @ hh:mm:tt')
				ssid = this.calledstationid.split("@")[0]
        var username = this.username
        if (username.match(/^([0-9a-f]{2}([-]|$)){6}$/i)){
          username = username.replace(/-/g, ":").toUpperCase()
        }
				table.append('<tr class="hidden"><td><a href="/users/'+username+'">'+username+'</a></td><td>'+date+'</td><td>'+this.nas+'</td><td>'+ssid+'</td></tr>')
			})
			showRows('#stales tr.hidden')
		}
	})
}

$(document).ready(function() {
	if (jQuery.browser.webkit) { //webkit specific styles in javascript, shame on me...
		$('.submit').css("padding", '5px');
	}

	$('td.comment').each(function() { //call shorten on each comment cell
		shorten(this);
	})
	
	//start masked input
	date = $('#date').val();
	mac = $('#macAddress').val();

	$('#macAddress').mask("**:**:**:**:**:**", {placeholder: "0"});
	$('#date').val(date);
	$('#macAddress').val(mac);
	//end masked input
	
	$('input.expiration').datepicker({minDate: new Date(), changeYear: true });
	
	
	$('tbody').each(function() { //give the odd rows the odd class styles
		var count = 1
		$(this).children('tr').each(function() {
			if (count % 2 == 1 && $(this).children('th').length < 1) {
				$(this).addClass("odd");
			}
			count += 1;
		})
	})
	
	var accountingCount = 1
	$('#accounting').children('div').each(function() {
		if (accountingCount % 2 == 1) {
				$(this).addClass("odd");
			}
			accountingCount += 1;
	})
	
	$('#accounting div').each(function() {
		var details = $(this).children('.details:first')
		details.before('<span><a class="more" href="javascript:void(0)">MORE DETAILS</a></span>');
		details.hide();
	})
	
	$('.more').live('click', function() {
		$(this).parent().next('.details').slideToggle();
		$(this).html() == "MORE DETAILS" ? $(this).html("FEWER DETAILS") : $(this).html("MORE DETAILS");
	})
	
	$('a.destroyUser').click(function() { //Destroy ajax call. Not unobtrousive, but who really runs with JS disabled anyway? Screw them...
		var answer = confirm("Are you sure you want to delete this account?")
		if (answer == true) {
			var href = $(this).attr("href").split("/")
			$.ajax({
				type: "DELETE",
				data: "id=" + href[2],
				url: "/" + href[1],
				success: function() {
					window.location = "/" + href[1]
				}
			})
			return false;
		}
	});
	
	$('form.#staleForm').submit(function() {
		getStales()
		return false
	})
	showRows('tr.hidden')
	getStales();
})


