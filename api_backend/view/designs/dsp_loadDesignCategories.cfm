<cfoutput query="designCategories">
	<li class="parent_li">
		<span data-list="my" data-level="group" data-item="#group_id#" data-loaded="0"><i class="glyphicon glyphicon-folder-close" style="color:##CCAB26;"></i> #group_name#</span>
		<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('group',#group_id#, #group_id#);">
			<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
		</a>
		<ul id="my_group_#group_id#">
               <li style="display:none">
               	<span><i class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></i> Loading</span>
			</li>
		</ul>
	</li>
</cfoutput>