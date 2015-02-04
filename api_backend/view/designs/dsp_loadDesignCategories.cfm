<cfoutput query="designCategories">
	<li class="parent_li">
		<span data-list="my" data-level="group" data-item="#cat_id#" data-item="" data-item2="#cat_id#" data-item3="#custom_cat_id#" data-custom="#isCustom#" data-cat-custom="#isCustom#" data-loaded="0"><i class="glyphicon glyphicon-folder-close" style="color:##CCAB26;"></i> #description#</span>
		<cfif aCount GT 0>
			<i class="glyphicon glyphicon-ban-circle" aria-hidden="true" title="You cannot delete this category because it is in use by the logos."></i>
		<cfelse>		
			<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('#cat_id#', '#custom_cat_id#', '0', 'group', '#isCustom#');">
			<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
			</a>
		</cfif>
		<ul id="my_group_#cat_id#_#custom_cat_id#_#isCustom#">
               <li style="display:none">
               	<span><i class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></i> Loading</span>
			</li>
		</ul>
	</li>
</cfoutput>

