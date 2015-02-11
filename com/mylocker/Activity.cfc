<cfcomponent displayname="Activity" hint="Manage Activities" output="false">

	<cfset dsn = "cwdbsql" />							<!--- Datasource name --->
	<cfset Activity_Table = "Activity" />				<!--- Table holding Activities --->

	<cffunction access="remote" name="list_v2" returntype="Query" >
		<cfargument name="store_id" required="false" default="" />
		<cfargument name="store_category" required="false" default="" />
		<cfargument name="apiProductExists" required="false" default="0" />
		<cfargument name="apiDesignCategoryID" required="false" default="0" />

		<!---API Queries--->
		<cfif apiProductExists NEQ "0">
			<cfquery name="qryActivity" datasource="#dsn#">
				<cfif apiDesignCategoryID gt 0>
					SELECT api_designcategory_activity_id as activity_id,
					CASE WHEN act.name is null THEN actc.name ELSE act.name END as name,
					0 as isDefault
					FROM api_designcategory_activities apa
					LEFT JOIN activity act on apa.activity_id = act.activity_id AND isCustom = 0
					LEFT JOIN activity_custom actc on apa.activity_id = actc.activity_id AND isCustom = 1
					WHERE apa.isActive = 1 
					AND api_designcategory_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#apiDesignCategoryID#" /> 	
					AND apa.shop_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					ORDER BY CASE WHEN act.name is null THEN actc.name ELSE act.name END				
				<cfelse> <!---No design category id passed, so show all of this store's activities--->
					SELECT api_designcategory_activity_id as activity_id,
					CASE WHEN scc.description is null THEN sc.description ELSE scc.description END + ' - ' +
					CASE WHEN act.name is null THEN actc.name ELSE act.name END as name,
					0 as isDefault
					FROM api_designcategory_activities apa
					LEFT JOIN activity act on apa.activity_id = act.activity_id AND isCustom = 0
					LEFT JOIN activity_custom actc on apa.activity_id = actc.activity_id AND isCustom = 1
					LEFT JOIN shop_category_custom scc on apa.category_custom_id = scc.Category_id
					LEFT JOIN shop_category sc on apa.category_id = sc.Category_id					
					WHERE apa.isActive = 1 
					AND apa.shop_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					ORDER BY CASE WHEN scc.description is null THEN sc.description ELSE scc.description END
					 + ' - ' + CASE WHEN act.name is null THEN actc.name ELSE act.name END
				</cfif>
			</cfquery>
		<cfelse>
			<cfif store_id is not "" and store_id is not "0">
				<!--- Check for 'I' Include only records in the Store_Activity_Link --->
				<cfquery name="qryActivity" datasource="#dsn#">
					SELECT		a.activity_id activity_id, a.name name, CASE WHEN b.id IS NULL THEN 0 ELSE 1 END isDefault
					FROM		Activity a
					LEFT JOIN	tbl_buildastore b ON b.activity = a.name AND b.id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					JOIN		Store_Activity_Link sa ON sa.activity_id = a.activity_id AND sa.store_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					WHERE		(sa.ExcludeOrInclude = 'I')
						AND		(a.name = b.activity or a.isActive = 1)
					ORDER BY	name
				</cfquery>

				<cfif qryActivity.RecordCount lt 2>
					<!--- get the shop's category_id --->
					<cfquery datasource="#dsn#" name="qryShopCategory">
						SELECT		category_id
						FROM		schoolcolors
						WHERE		id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#store_id#" />
					</cfquery>
					<!--- No Include-Only records, so grab normal, excluding 'E' records --->
					<cfquery datasource="#dsn#" name="qryActivity">
						SELECT 		DISTINCT a.activity_id activity_id, a.name name, CASE WHEN b.id IS NULL THEN 0 ELSE 1 END isDefault
						FROM		shop_Category_Activity_link scal
						INNER JOIN	Activity a ON a.activity_id = scal.Activity_id
						LEFT JOIN	tbl_buildastore b ON b.activity = a.name AND b.id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
						LEFT JOIN	Store_Activity_Link sa ON sa.activity_id = a.activity_id AND sa.store_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
	<!---					WHERE		((sa.ExcludeOrInclude IS NULL OR sa.ExcludeOrInclude != 'E') OR (sa.ExcludeOrInclude = 'I')) --->
						WHERE 		(sa.ExcludeOrInclude IS NULL or sa.ExcludeOrInclude != 'E')
							AND 	scal.Category_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qryShopCategory.category_id#" />
							AND 	(a.name = b.activity or a.isActive = 1)
						ORDER BY	name
					</cfquery>
				</cfif>
	            
	            <cfif qryActivity.RecordCount IS 0>
	            	<cfquery datasource="#dsn#" name="getActivity">
	                    SELECT b.activity, COALESCE(a.activity_id, 0) activity_id
	                    FROM tbl_buildastore b
	                    	LEFT OUTER JOIN Activity a ON a.name = 'custom'
	                    WHERE id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
	                </cfquery>
	            	<cfset Temp = QueryAddRow(qryActivity) />            	              
	            	<cfset Temp = QuerySetCell(qryActivity, "activity_id", "#getActivity.activity_id#", 1) />
		            <cfset Temp = QuerySetCell(qryActivity, "name", "#getActivity.activity#", 1) />
	                <cfset Temp = QuerySetCell(qryActivity, "isDefault", "1", 1) />
	            </cfif>
	        <cfelseif store_category is not "" and store_category is not "0">
	        	<cftry>
	        		<cfquery name="qryActivity" datasource="#dsn#">
						SELECT 		a.activity_id activity_id, a.name name, 0 isDefault
						FROM		shop_Category_Activity_link scal
						INNER JOIN	Activity a ON a.activity_id = scal.Activity_id
						WHERE		scal.Category_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#store_category#" />
							AND 	a.isActive = 1
						ORDER BY	name
	        		</cfquery>
	        		<cfcatch>

	        		</cfcatch>
	        	</cftry>
			<cfelse>
				<!--- store_id and store_category were not passed in, so just grab all the Activities --->
				<cfquery name="qryActivity" datasource="#dsn#">
					SELECT		a.activity_id activity_id, a.name name, 0 isDefault
					FROM		Activity a
					WHERE   	a.isActive = 1
					ORDER BY	name
				</cfquery>

			</cfif>
		</cfif>
		<cfreturn qryActivity />

	</cffunction>

	<cffunction access="remote" name="list" returntype="Query" >
		<cfargument name="store_id" required="false" default="" />
		<cfargument name="store_category" required="false" default="" />

		<cfif store_id is not "">
			<!--- Check for 'I' Include only records in the Store_Activity_Link --->
			<cfquery name="qryActivity" datasource="#dsn#">
				SELECT		0 activity_id, 'COUNT' name, COUNT(activity_id) isDefault
				FROM		Activity
				UNION
					SELECT		a.activity_id activity_id, a.name name, CASE WHEN b.id IS NULL THEN 0 ELSE 1 END isDefault
					FROM		Activity a
					LEFT JOIN	tbl_buildastore b ON b.activity = a.name AND b.id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					JOIN		Store_Activity_Link sa ON sa.activity_id = a.activity_id AND sa.store_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
					WHERE		(sa.ExcludeOrInclude = 'I')
						AND		(a.name = b.activity or a.isActive = 1)
				ORDER BY	isDefault DESC, name
			</cfquery>

			<cfif qryActivity.RecordCount lt 2>
				<!--- get the shop's category_id --->
				<cfquery datasource="#dsn#" name="qryShopCategory">
					SELECT		category_id
					FROM		schoolcolors
					WHERE		id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#store_id#" />
				</cfquery>
				<!--- No Include-Only records, so grab normal, excluding 'E' records --->
				<cfquery datasource="#dsn#" name="qryActivity">
					SELECT		0 activity_id, 'COUNT' name, COUNT(a.activity_id) isDefault
					FROM		shop_Category_Activity_link scal
					INNER JOIN	Activity a ON a.activity_id = scal.Activity_id
					WHERE		scal.Category_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qryShopCategory.category_id#" />
					UNION
						SELECT 		a.activity_id activity_id, a.name name, CASE WHEN b.id IS NULL THEN 0 ELSE 1 END isDefault
						FROM		shop_Category_Activity_link scal
						INNER JOIN	Activity a ON a.activity_id = scal.Activity_id
						LEFT JOIN	tbl_buildastore b ON b.activity = a.name AND b.id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
						LEFT JOIN	Store_Activity_Link sa ON sa.activity_id = a.activity_id AND sa.store_id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#store_id#" />
						WHERE		((sa.ExcludeOrInclude IS NULL OR sa.ExcludeOrInclude != 'E') OR (sa.ExcludeOrInclude = 'I'))
									AND scal.Category_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qryShopCategory.category_id#" />
									AND (a.name = b.activity or a.isActive = 1)
						ORDER BY	isDefault DESC, name
				</cfquery>
			</cfif>

		<cfelse>
			<!--- store_id was not passed in, so just grab all the Activities --->
			<cfquery name="qryActivity" datasource="#dsn#">
				SELECT		0 activity_id, 'COUNT' name, COUNT(activity_id) isDefault
				FROM		Activity
				UNION
					SELECT	a.activity_id activity_id, a.name name, 0 isDefault
					FROM	Activity a
					WHERE   a.isActive = 1
				ORDER BY	isDefault DESC, name
			</cfquery>

		</cfif>

		<cfreturn qryActivity />

	</cffunction>
</cfcomponent>