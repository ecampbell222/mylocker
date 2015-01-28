<cfif attributes.list_type IS "mylocker">
	<li>
		<span data-loaded="0">
			Add Custom Activity
		</span>
	</li>
</cfif>
<cfoutput query="activities">
	<li>	
		<span data-list="#attributes.list_type#" data-group-id="#attributes.cat_id#" data-level="activity" data-item="#activities.activity_id#" data-loaded="0" <cfif attributes.list_type IS "mylocker">style="cursor: pointer;"</cfif>>
			#activities.name# 
		</span>
		<cfif attributes.list_type IS NOT "mylocker">
			<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('#session.authUser.shop_id#','#attributes.cat_id#','#attributes.cat_id_cust#','#activities.activity_id#','activity', '#attributes.is_custom#');">
				<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
			</a>
		</cfif>
	</li>
</cfoutput>