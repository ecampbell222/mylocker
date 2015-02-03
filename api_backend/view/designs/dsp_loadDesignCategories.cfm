<cfoutput query="designCategories">
	<li class="parent_li">
		<span data-list="my" data-level="group" data-item="#cat_id#" data-item="" data-item2="#cat_id#" data-item3="#custom_cat_id#" data-shop="#session.authUser.shop_id#" data-custom="#isCustom#" data-cat-custom="#isCustom#" data-loaded="0"><i class="glyphicon glyphicon-folder-close" style="color:##CCAB26;"></i> #description#</span>
		<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('#session.authUser.shop_id#','#cat_id#', '#custom_cat_id#', '', 'group', '#isCustom#');">
			<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
		</a>
		<ul id="my_group_#cat_id#_#custom_cat_id#_#isCustom#">
               <li style="display:none">
               	<span><i class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></i> Loading</span>
			</li>
		</ul>
	</li>
</cfoutput>

