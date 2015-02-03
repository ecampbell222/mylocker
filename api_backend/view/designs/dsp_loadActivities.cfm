<cfif attributes.list_type IS "mylocker">
	<li>
		<cfset custSpanID = "spnAddCustAct_" & attributes.cat_id & "_" & attributes.cat_id_cust>
		<span id="<cfoutput>#custSpanID#</cfoutput>" data-loaded="0" style="cursor:cell;background-color:#ffffff;" onclick="javascript:setCustomTextbox('AddCustAct','<cfoutput>#attributes.cat_id#</cfoutput>','<cfoutput>#attributes.cat_id_cust#</cfoutput>','<cfoutput>#attributes.is_custom#</cfoutput>');">
			<i class="glyphicon glyphicon-plus" aria-hidden="true"></i> Add Custom Activity
		</span>
	</li>
</cfif>
<cfoutput query="activities">
	<li>	
		<span data-list="#attributes.list_type#" data-custom="#activities.isCustom#" data-shop="#session.authUser.shop_id#" data-item="#activities.activity_id#" data-item2="#attributes.cat_id#" data-item3="#attributes.cat_id_cust#" data-level="activity" data-cat-custom="#attributes.is_custom#" data-loaded="0" <cfif attributes.list_type IS "mylocker">style="cursor: pointer;"</cfif>>
			#activities.name# 
		</span>
		<cfif attributes.list_type IS "mylocker" AND activities.isCustom IS "1">
			<a data-toggle="confirmation" data-placement="top" onConfirm="deleteCustom('#attributes.cat_id#','#attributes.cat_id_cust#','#activities.activity_id#', '#attributes.is_custom#');">
				<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
			</a>
		</cfif>	
		<cfif attributes.list_type IS NOT "mylocker">
			<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('#session.authUser.shop_id#','#attributes.cat_id#','#attributes.cat_id_cust#','#activities.activity_id#','activity', '#activities.isCustom#');">
				<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
			</a>
		</cfif>
	</li>
</cfoutput>