<cfoutput query="activities">
	<li>
		<span data-list="#attributes.list_type#" data-group-id="#attributes.cat_id#" data-level="activity" data-item="#activities.activity_id#" data-loaded="0" <cfif attributes.list_type IS "MyLocker">style="cursor: pointer;"</cfif>>
			#activities.name#
		</span>
		<cfif attributes.list_type IS NOT "MyLocker">
			<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('activity',#activities.activity_id#, #attributes.cat_id#);">
				<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
			</a>
		</cfif>
	</li>
</cfoutput>