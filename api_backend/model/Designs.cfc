<!---
  --- Designs
  --- -------
  ---
  --- author: ed
  --- date:   01/30/15
  --->
<cfcomponent accessors="true" output="false" persistent="false" extends="BaseObject">
	<cffunction name="DesignCategories" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="mylocker" />

		<cfset var local = {} />

		<!---Grabs all shop categories for Select Category side of api--->
		<cfquery name="local.getShopCategories" datasource="cwdbsql">
			SELECT case when isCustom = 0 then category_id else 0 end as cat_id,
			case when isCustom = 1 then category_id else 0 end as custom_cat_id, 
			description, isCustom FROM
			<cfif arguments.list_type IS NOT "mylocker">
				(SELECT c.category_id, description, 0 as isCustom FROM shop_Category c
				INNER JOIN api_designcategories apd1 ON c.category_id = apd1.category_id
				WHERE description <> 'Custom' 
				AND apd1.shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				UNION
				SELECT cs.category_id, description, 1 as isCustom FROM shop_Category_Custom cs
				INNER JOIN api_designcategories apd2 ON cs.category_id = apd2.category_custom_id
				WHERE apd2.shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				) 
			<cfelse>
				(SELECT category_id, description, 0 as isCustom FROM shop_Category c 
					WHERE description <> 'Custom'
					UNION
					SELECT category_id, description, 1 as isCustom FROM shop_Category_Custom cs
					WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				)
			</cfif>
			AS cat 
			ORDER BY description
		</cfquery>

		<cfreturn local.getShopCategories />
	</cffunction>
	
	<!---Gets a count of categories for a shop--->
	<cffunction name="ShopHasDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.checkDesigns" datasource="cwdbsql">
			SELECT sum(hasDesignsCnt) as hasDesigns FROM
			(SELECT COUNT(category_id) as hasDesignsCnt
			FROM api_designcategories WITH (NOLOCK)
			WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			UNION 
			SELECT COUNT(category_id) as hasDesignsCnt
			FROM api_designcategory_activities WITH (NOLOCK)
			WHERE isCustom = 1 
			AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			) as dCheck
		</cfquery>

		<cfreturn local.checkDesigns.hasDesigns />
	</cffunction>
	
	<!---Grabs activities for a category--->
	<cffunction name="GetCategoryActivities" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="category_cust_id" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="mylocker" />

		<cfset passCatID = arguments.category_id>
		<cfif arguments.is_custom EQ "1">
			<cfset passCatID = arguments.category_cust_id>
		</cfif>

		<cfset var local = {} />

		<cfquery name="local.getActivities" datasource="cwdbsql">
			SELECT act.activity_id, act.isCustom, act.name FROM 
			<cfif arguments.is_custom EQ "1">
				(SELECT activity_id, 1 as isCustom, name FROM 
				activity_custom WHERE category_cust_id = <cfqueryparam value="#passCatID#" cfsqltype="cf_sql_bigint" /> 
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />) act
				<cfif arguments.list_type NEQ "mylocker">
					INNER JOIN api_designcategory_activities api on act.activity_id = api.activity_id
					AND act.isCustom = api.isCustom AND api.category_custom_id = <cfqueryparam value="#passCatID#" cfsqltype="cf_sql_bigint" />
				</CFIF>
			<cfelse>
				(SELECT activity_id, 0 as isCustom, name FROM activity WHERE category_id = <cfqueryparam value="#passCatID#" cfsqltype="cf_sql_bigint" />
				UNION
				SELECT activity_id, 1 as isCustom, name FROM activity_custom WHERE category_id = <cfqueryparam value="#passCatID#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />) act
				<cfif arguments.list_type NEQ "mylocker">
					INNER JOIN api_designcategory_activities api on act.activity_id = api.activity_id
					AND act.isCustom = api.isCustom AND api.category_id = <cfqueryparam value="#passCatID#" cfsqltype="cf_sql_bigint" />
				</cfif>
			</cfif>
			ORDER BY name
		</cfquery>

		<cfreturn local.getActivities />
	</cffunction>

	<!--Add custom categories and activities-->
	<cffunction name="AddCustom" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="cat_id" type="string" required="true" />
		<cfargument name="cat_cust_id" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />
		<cfargument name="category_name" type="string" required="true" />
		<cfset retVal = "1">

		<cfset var local = {} />

		<cfif cat_id EQ "" and cat_cust_id EQ "">
			<cfquery name="local.dupCheck" datasource="cwdbsql">
				SELECT sum(catCount) as catCountTot FROM
				(SELECT count(category_id) as catCount FROM shop_category 
				WHERE description = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" />
				UNION
				SELECT count(category_id) as catCount FROM shop_category_custom 
				WHERE description = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" />
				) as c
			</cfquery>
			<cfset dupCount = local.dupCheck.catCountTot>			
			<cfif dupCount GT 0>
				<cfset retVal = "dup">
			<cfelse>
				<cfquery name="local.insCat" datasource="cwdbsql">
					INSERT INTO shop_category_custom (description, created_dt, isActive, shop_id)
					VALUES (
 						<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" />,
 						getdate(), 0,
 						<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
					)
				</cfquery>
			</cfif>
			
		<cfelse>
			<cfif arguments.is_custom EQ "1">
				<cfquery name="local.dupCheck" datasource="cwdbsql">
					SELECT count(activity_id) as actCountTot FROM activity_custom 
					WHERE name = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" /> 
					AND category_cust_id = <cfqueryparam value="#arguments.cat_cust_id#" cfsqltype="cf_sql_bigint" />
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				</cfquery>
				<cfset dupCount = local.dupCheck.actCountTot>			
				<cfif dupCount GT 0>
					<cfset retVal = "dup">
				<cfelse>
					<cfquery name="local.insCat" datasource="cwdbsql">
						INSERT INTO activity_custom (name, category_id, isActive, shop_id, category_cust_id)
						VALUES (
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" />,
							0, 0, 
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />,
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.cat_cust_id#" />
						)
					</cfquery>
				</cfif>									
			<cfelse>
				<cfquery name="local.dupCheck" datasource="cwdbsql">
					SELECT sum(actCount) as actCountTot FROM
					(SELECT count(activity_id) as actCount FROM activity 
					WHERE name = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" /> 
					AND category_id = <cfqueryparam value="#arguments.cat_id#" cfsqltype="cf_sql_bigint" />					
					UNION
					SELECT count(activity_id) as actCount FROM activity_custom 
					WHERE name = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" /> 
					AND category_id = <cfqueryparam value="#arguments.cat_id#" cfsqltype="cf_sql_bigint" />
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
					) as a
				</cfquery>
				<cfset dupCount = local.dupCheck.actCountTot>			
				<cfif dupCount GT 0>
					<cfset retVal = "dup">
				<cfelse>
					<cfquery name="local.insCat" datasource="cwdbsql">
						INSERT INTO activity_custom (name, category_id, isActive, shop_id, category_cust_id)
						VALUES (
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.category_name#" />,
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.cat_id#" />, 
							0, 
							<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />,
							0
						)
					</cfquery>
				</cfif>				
			</cfif>
		</cfif>

		<cfreturn retVal />
	</cffunction>

	<!--Delete custom categories and activities-->
	<cffunction name="DeleteCustom" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="cat_id" type="string" required="true" />
		<cfargument name="cat_cust_id" type="string" required="true" />
		<cfargument name="activity_id" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />

		<cfset var local = {} />

		<cfif arguments.activity_id NEQ "0">
			<cfset delDesigns = This.DeleteDesigns(arguments.shop_id, arguments.cat_id, arguments.cat_cust_id, arguments.activity_id, 'activity', arguments.is_custom) />			
			<cfquery name="local.deleteCustomAct" datasource="cwdbsql">
				DELETE FROM activity_custom				
				WHERE activity_id = <cfqueryparam value="#arguments.activity_id#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>			
		<cfelse>
			<cfset delDesigns = This.DeleteDesigns(arguments.shop_id, arguments.cat_id, arguments.cat_cust_id, arguments.activity_id, 'group', arguments.is_custom) />			
			<cfquery name="local.deleteCustomAct" datasource="cwdbsql">
				DELETE FROM activity_custom		
				WHERE category_cust_id = <cfqueryparam value="#arguments.cat_cust_id#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />		
			</cfquery>				
			<cfquery name="local.deleteCustomCat" datasource="cwdbsql">
				DELETE FROM shop_category_custom 
				WHERE category_id = <cfqueryparam value="#arguments.cat_cust_id#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>
		</cfif>

		<cfreturn true />
	</cffunction>

	<!---Inserts selected categories or activities--->
	<cffunction name="AddDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="activity_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="category_cust_id" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />
		<cfargument name="cat_cust" type="string" required="true" />

		<cfset var local = {} />
		<cfset retVal = "">

		<!---Check to see if category has any activities--->
		<cfquery name="local.actExists" datasource="cwdbsql">
			<cfif arguments.cat_cust EQ "1">
				SELECT count(activity_id) as actCount
				FROM activity_custom 
				WHERE category_cust_id = <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			<cfelse>
				SELECT sum(subCount) as actCount FROM
				(SELECT count(activity_id) as subCount
				FROM activity_custom WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				UNION
				SELECT count(activity_id) as subCount
				FROM activity WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />) as Cnt
			</cfif>
		</cfquery>
		<cfset actCount = local.actExists.actCount>

		<!---Do not add categories that have 0 activities--->
		<cfif actCount EQ 0>
			<cfset retVal = "noact">
		<cfelse>
			<!---Check if category exists already, if so, set id--->
			<cfquery name="local.catExists" datasource="cwdbsql">
				SELECT count(api_designcategory_id) as catCount 
				FROM api_designcategories with (updlock,serializable) 
				<cfif arguments.cat_cust EQ "1">
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" /> 
				<cfelse>
					WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
				</cfif>
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>
			<cfset catCount = local.catExists.catCount>

			<!---Category was moved to right column, insert category if not exists--->
			<cfif catCount EQ "0">
				<cfquery name="local.insertCategory" datasource="cwdbsql">
					BEGIN tran
				    INSERT INTO api_designcategories(category_id, category_custom_id, shop_id)
				    <cfif arguments.cat_cust EQ "1">
						VALUES (0, <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" />,
				    <cfelse>
						VALUES (<cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />, 0,
				    </cfif>
				    <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />)
					COMMIT tran
				</cfquery>
			</cfif>

			<!---Select all activities to be inserted--->
			<cfquery name="local.insertActivities" datasource="cwdbsql">
				INSERT INTO api_designcategory_activities (category_id, category_custom_id, activity_id, shop_id, isActive, isCustom)
				SELECT insCatID, insCustCatID, insActID, insShopID, 0, insCustom FROM
				<cfif arguments.level IS "activity">
					<cfif arguments.cat_cust EQ "1">
						<!---Insert single custom activity from custom category--->
						(SELECT 0 as insCatID, category_cust_id as insCustCatID, activity_id as insActID, 
						shop_id as insShopID, 1 as insCustom 
						FROM activity_custom ac 
						WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
						AND category_cust_id = <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" /> 
						AND activity_id = <cfqueryparam value="#arguments.activity_id#" cfsqltype="cf_sql_bigint" />
						AND not activity_id IN (
							SELECT activity_id FROM api_designcategory_activities api
							WHERE api.category_custom_id = ac.category_cust_id
							AND api.activity_id = ac.activity_id
							AND api.shop_id = ac.shop_id
							AND isCustom = 1
						)) as cst
					<cfelse>
						<cfif arguments.is_custom EQ "1">
							<!---insert single custom activity from regular category--->
							(SELECT category_id as insCatID, 0 as insCustCatID, activity_id as insActID, 
							shop_id as insShopID, 1 as insCustom 
							FROM activity_custom ac 
							WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
							AND category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
							AND activity_id = <cfqueryparam value="#arguments.activity_id#" cfsqltype="cf_sql_bigint" />
							AND not activity_id IN (
								SELECT activity_id FROM api_designcategory_activities api
								WHERE api.category_id = ac.category_id
								AND api.activity_id = ac.activity_id
								AND api.shop_id = ac.shop_id
								AND isCustom = 1
							)) as cst
						<cfelse>
							<!---insert single regular activity from regular category--->
							(SELECT category_id as insCatID, 0 as insCustCatID, activity_id as insActID, 
							'#arguments.shop_id#' as insShopID, 0 as insCustom 
							FROM activity ac 
							WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
							AND activity_id = <cfqueryparam value="#arguments.activity_id#" cfsqltype="cf_sql_bigint" />
							AND not activity_id IN (
								SELECT activity_id FROM api_designcategory_activities api
								WHERE api.category_id = ac.category_id
								AND api.activity_id = ac.activity_id
								AND isCustom = 0
							)) as cst
						</cfif>
					</cfif>
				<cfelse>
					<cfif arguments.is_custom EQ "1">
						<!---insert all custom activites from custom category--->
						(SELECT 0 as insCatID, category_cust_id as insCustCatID, activity_id as insActID, 
						shop_id as insShopID, 1 as insCustom 
						FROM activity_custom ac 
						WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
						AND category_cust_id = <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" /> 
						AND not activity_id IN (
							SELECT activity_id FROM api_designcategory_activities api
							WHERE api.category_custom_id = ac.category_cust_id
							AND api.shop_id = ac.shop_id
							AND isCustom = 1
						)) as cst
					<cfelse>
						<!---insert all activites from regular category--->
						(
						SELECT category_id as insCatID, 0 as insCustCatID, activity_id as insActID, 
						shop_id as insShopID, 1 as insCustom 
						FROM activity_custom ac 
						WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
						AND category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
						AND not activity_id IN (
							SELECT activity_id FROM api_designcategory_activities api
							WHERE api.category_id = ac.category_id
							AND api.shop_id = ac.shop_id
							AND isCustom = 1
						) UNION
						SELECT category_id as insCatID, 0 as insCustCatID, activity_id as insActID, 
						'#arguments.shop_id#' as insShopID, 0 as insCustom 
						FROM activity ac 
						WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
						AND not activity_id IN (
							SELECT activity_id FROM api_designcategory_activities api
							WHERE api.category_id = ac.category_id
							AND isCustom = 0
						)) as cst
					</cfif>
				</cfif>

			</cfquery>
		</cfif>

		<cfreturn retVal />
	</cffunction>

	<!---Deletes selected categories/activities--->
	<cffunction name="DeleteDesigns" output="true" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="category_cust_id" type="string" required="true" />
		<cfargument name="data" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />

		<cfset var local = {} />

		<!---Delete individual activities--->
		<cfquery name="local.deleteActivities" datasource="cwdbsql">
			DELETE FROM api_designcategory_activities 
			WHERE isCustom = <cfqueryparam value="#arguments.is_custom#" cfsqltype="cf_sql_int" />
			AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			<cfif arguments.is_custom EQ "1">
				AND category_custom_id = <cfqueryparam value="#arguments.category_cust_id#" cfsqltype="cf_sql_bigint" />
			<cfelse>
				AND category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
			</cfif>
			<cfif arguments.level NEQ "group">
				AND activity_id = <cfqueryparam value="#arguments.data#" cfsqltype="cf_sql_bigint" />			
			</cfif>				
		</cfquery>

		<!---Delete all categories from selected api with 0 activities--->
		<cfquery name="local.deleteCategoriesCust" datasource="cwdbsql">
			DELETE FROM api_designcategories 
			WHERE not category_custom_id IN	(
				SELECT distinct category_custom_id FROM api_designcategory_activities
				WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" /> 
				AND category_custom_id > 0
			)
			AND category_id = 0
		</cfquery>
		<cfquery name="local.deleteCategories" datasource="cwdbsql">
			DELETE FROM api_designcategories WHERE not category_id IN
			(SELECT distinct category_id FROM api_designcategory_activities
				WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" /> 
				AND category_id > 0
			)
			AND category_custom_id = 0
		</cfquery>

		<cfreturn true />
	</cffunction>

</cfcomponent>