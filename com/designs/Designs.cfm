<cfsilent>
	<cfparam name="activityId" default="" />
	<cfparam name="designTypeId" default="1" />
	<cfparam name="frontDesignTypeId" default="#designTypeId#" />
	<cfparam name="designId" default="0" />
	<cfparam name="schoolsId" default="" />
	<cfparam name="graphicFile" default="" />
	<cfparam name="appMode" default="" />
	<cfparam name="designStatus" default="-99" />	<!--- used in manager mode only --->
	<cfparam name="isSVG" default="0" />
	<cfparam name="d" default="0" />
	<cfparam name="g" default="" />

	<cfif designId neq 0>
		<cfinvoke component="com.designs.Design" method="getDesignsById" returnVariable="allDesigns">
			<cfinvokeargument name="designId" value="#designId#" />
			<cfinvokeargument name="graphicFile" value="#graphicFile#" />
		</cfinvoke>
	<cfelse>
		<cfif appMode eq "api">
			<cfinvoke component="com.designs.Design_api" method="list" returnVariable="allDesigns">
				<cfinvokeargument name="designTypeId" value="#designTypeId#" />
				<cfinvokeargument name="frontDesignTypeId" value="#frontDesignTypeId#" />
				<cfinvokeargument name="activityId" value="#activityId#" />
				<cfinvokeargument name="schoolsId" value="#schoolsId#" />
				<cfinvokeargument name="appMode" value="#appMode#" />
				<cfinvokeargument name="designStatus" value="#designStatus#" />
				<cfinvokeargument name="isSVG" value="#isSVG#" />
				<cfinvokeargument name="d" value="#d#" />
				<cfinvokeargument name="g" value="#g#" />
			</cfinvoke>		
		<cfelse>	
			<cfinvoke component="com.designs.Design" method="list" returnVariable="allDesigns">
				<cfinvokeargument name="designTypeId" value="#designTypeId#" />
				<cfinvokeargument name="frontDesignTypeId" value="#frontDesignTypeId#" />
				<cfinvokeargument name="activityId" value="#activityId#" />
				<cfinvokeargument name="schoolsId" value="#schoolsId#" />
				<cfinvokeargument name="appMode" value="#appMode#" />
				<cfinvokeargument name="designStatus" value="#designStatus#" />
				<cfinvokeargument name="isSVG" value="#isSVG#" />
				<cfinvokeargument name="d" value="#d#" />
				<cfinvokeargument name="g" value="#g#" />
			</cfinvoke>
		</cfif>
	</cfif>
</cfsilent>
<cfcontent type="text/xml" reset="true" /><cfoutput>#allDesigns#</cfoutput>