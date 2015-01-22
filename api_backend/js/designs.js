$(function(){  
	$('.tree li:has(ul)').addClass('parent_li').find(' > span').attr('title', 'Expand this branch');
	setDesignsTree();	
	$("#myUploadedDesigns").click(function(){
		SaveShowMyUploads();
	});
	if($("#myUploadedDesigns").prop('checked')){
		$("#design-selection").toggle();
	}
});
function SaveShowMyUploads(){
	$("#design-selection").toggle();
	
	$.ajax({
		type: 'POST',
		url: '/?t=s.SaveShowMyUploads',
		dataType: 'html',
		data:{
			myDesignsOnly: $("#myUploadedDesigns").prop('checked')
		},
		timeout: 30000,
		success: function(result) {
			$("#myUploadedDesignsSaved").html(result);
			$("#myUploadedDesignsSaved").fadeIn('slow', function(){
				$("#myUploadedDesignsSaved").fadeOut(3600);
			});
			
		},
		failure: function() {
			
		}
	});	
}
function loadActivities(group, list){
	$.ajax({
		type: 'POST',
		url: '/?t=d.LoadActivities',
		dataType: 'html',
		data:{
			group_id: group,
			list_type: list
		},
		timeout: 30000,
		success: function(result) {
			$("#" + list + "_group_"+group).html(result);
			$('.tree li.parent_li > span').unbind( "click" );
			setDesignsTree();
			setConfirmationPopUps();
		},
		failure: function() {
			
		}
	});	
}
function addToMyDesigns(level, data, group){
	$.ajax({
		type: 'POST',
		url: '/?t=d.AddDesigns',
		dataType: 'html',
		data:{
			level: level,
			data: data,
			group: group			
		},
		timeout: 30000,
		success: function(result) {
			$(".my-designs").html(result);
			setDesignsTree();
			setConfirmationPopUps();
			$("#no-designs-info").hide();
		},
		failure: function() {
			
		}
	});
}
function deleteDesign(level, data, group){
	$.ajax({
		type: 'POST',
		url: '/?t=d.DeleteDesigns',
		dataType: 'html',
		data:{
			level: level,
			data: data,
			group: group			
		},
		timeout: 30000,
		success: function(result) {
			$(".my-designs").html(result);
			setDesignsTree();
			setConfirmationPopUps();
		},
		failure: function() {
			
		}
	});
}
function setDesignsTree(){
	$('.tree li.parent_li > span').click(function (e) {
	    var children = $(this).parent('li.parent_li').find(' > ul > li');
	    if (children.is(":visible")) {
	        children.hide('fast');
	        $(this).attr('title', 'Expand this branch').find(' > i').addClass('glyphicon-folder-close').removeClass('glyphicon-folder-open');
	    } else {
	        children.show('fast');
	        $(this).attr('title', 'Collapse this branch').find(' > i').addClass('glyphicon-folder-open').removeClass('glyphicon-folder-close');
	 
	        if ($(this).attr('data-loaded') == 0){
		        if ($(this).attr('data-level') == "group"){
		        	loadActivities($(this).attr('data-item'),$(this).attr('data-list'));
		        	$(this).attr('data-loaded','1');
		        } 
	        }
	    }
	    e.stopPropagation();
	});
	$(".mylocker-designs span").draggable({
		addClasses: true,
		// Chrome has problems with displaying dragged
		// element when appendTo is default "body"
		appendTo : ".lock",
		helper : "clone",
		appendTo: "body"
	});
	$(".my-designs").droppable({
		addClasses: true,
		activeClass : "listActive",
		//hoverClass : "listHover",
		accept : ":not(.ui-sortable-helper)",
		drop : function(event, ui) {
			$(this).find(".placeholder").remove();			
			var list = $("<li class='parent_li'></li>").html(ui.draggable.html());
			$(list).appendTo(this);
			addToMyDesigns(ui.draggable.attr('data-level'),ui.draggable.attr('data-item'),ui.draggable.attr('data-group-id'));
		}
	})
}