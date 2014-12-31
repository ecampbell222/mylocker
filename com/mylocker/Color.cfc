<cfcomponent displayname="Activity" hint="Manage Activities" output="false">

	<cfset dsn = "cwdbsql" />							<!--- Datasource name --->
	<cfset Color_Table = "Color" />						<!--- Table holding Activities --->

	<cffunction access="remote" name="getColors" returntype="Query" >
		<cfargument name="store_id" required="false" default="" />
		<cfargument name="store_category" required="false" default="" />
		
		<cfquery datasource="#dsn#" name="qryColors">
			SELECT hex,descr
			FROM Color
		</cfquery>
		
		<cfreturn qryColors />
		
	</cffunction>

	<cffunction access="remote" name="getColorsOrdered" returntype="Query" >
		<cfargument name="store_id" required="false" default="" />
		<cfargument name="store_category" required="false" default="" />
		<cfargument name="color1" required="false" default="0xFF0" />
		<cfargument name="color2" required="false" default="0xFF0" />
		<cfargument name="color3" required="false" default="0xFF0" />
		<cfargument name="color4" required="false" default="0xFF0" />
		<cfargument name="color5" required="false" default="0xFF0" />
		<cfargument name="color6" required="false" default="0xFF0" />
		<cfargument name="color7" required="false" default="0xFF0" />
		<cfargument name="color8" required="false" default="0xFF0" />
		<cfargument name="color9" required="false" default="0xFF0" />
		<cfargument name="color10" required="false" default="0xFF0" />
		<cfargument name="primary" required="false" default="0xFF0" />
		<cfargument name="second" required="false" default="0xFF0" />
		<cfargument name="third" required="false" default="0xFF0" />
		<cfargument name="design_type_id" required="false" default="1" />
		
		<cfif design_type_id is not 3>
			<cfquery datasource="#dsn#" name="qryColors">
				SELECT hex,descr,0 isExtra
				FROM Color
				WHERE ( hex = '000000'
						OR hex = 'FFFFFF'
						OR hex = '999999'
						OR hex = SUBSTRING('#primary#',5,6)
						OR hex = SUBSTRING('#second#',5,6)
						OR hex = SUBSTRING('#third#',5,6)
				) AND ( Color.color_id NOT IN (SELECT color_id FROM Inactive_Print_Colors))
				UNION
				SELECT hex,descr,1 isExtra
				FROM Color
				WHERE ( hex != '000000'
						AND hex != 'FFFFFF'
						AND hex != '999999'
						AND hex != SUBSTRING('#primary#',5,6)
						AND hex != SUBSTRING('#second#',5,6)
						AND hex != SUBSTRING('#third#',5,6) 
				) AND ( Color.color_id NOT IN (SELECT color_id FROM Inactive_Print_Colors))
				ORDER BY isExtra DESC
			</cfquery>
		<cfelse>
			<!--- for embroidery, color_id must be in the color_embroidery_map table --->	
			<cfquery datasource="#dsn#" name="qryColors">
				SELECT hex,descr,0 isExtra
				FROM Color
				WHERE ( hex = '000000'
						OR hex = 'FFFFFF'
						OR hex = '999999'
						OR hex = SUBSTRING('#primary#',5,6)
						OR hex = SUBSTRING('#second#',5,6)
						OR hex = SUBSTRING('#third#',5,6)
				) AND ( Color.color_id IN (SELECT color_id FROM color_embroidery_map))
				UNION
				SELECT hex,descr,1 isExtra
				FROM Color
				WHERE ( hex != '000000'
						AND hex != 'FFFFFF'
						AND hex != '999999'
						AND hex != SUBSTRING('#primary#',5,6)
						AND hex != SUBSTRING('#second#',5,6)
						AND hex != SUBSTRING('#third#',5,6) 
				) AND ( Color.color_id IN (SELECT color_id FROM color_embroidery_map))
				ORDER BY isExtra DESC
			</cfquery>
		</cfif>
		
		<cfreturn qryColors />
		
	</cffunction>

	<cffunction name="getPrinterColors" access="remote" returntype="Query">
		<cfquery datasource="#dsn#" name="qryColors">
			SELECT DISTINCT		hex,old_hex,printer_hex
			FROM				Color
		</cfquery>
		<cfreturn qryColors />
	</cffunction>
	
	<cffunction name="getBestPrintColors" access="public" returntype="struct">
		<cfargument name="pcolor" required="false" default="000000" hint="Product Color" />
		<cfargument name="scolor1" required="false" default="000000" hint="Shop color 1" />
		<cfargument name="scolor2" required="false" default="999999" hint="Shop color 2" />
		<cfargument name="scolor3" required="false" default="EEEEEE" hint="Shop color 3" />
		<cfset var black = '000000' />
		<cfset var gray = '999999' />
		<cfset var white = 'EEEEEE' />
		<cfset var retval = StructNew() />
		
		<cfif contrast(scolor1,pcolor) gt 70>
			<cfset retval.primary = scolor1 />
			<cfset retval.secondary = scolor2 />
			<cfset retval.tertiary = scolor3 />
		<cfelseif contrast(scolor2,pcolor) gt 70>
			<cfset retval.primary = scolor2 />
			<cfset retval.secondary = scolor1 />
			<cfset retval.tertiary = scolor3 />
		<cfelseif contrast(scolor3,pcolor) gt 70>
			<cfset retval.primary = scolor3 />
			<cfset retval.secondary = scolor1 />
			<cfset retval.tertiary = scolor2 />
		<cfelseif contrast(black,pcolor) gt 70>
			<cfset retval.primary = black />
			<cfif scolor2 is not black>
				<cfset retval.secondary = scolor2 />
			<cfelseif scolor3 is not black>
				<cfset retval.secondary = scolor3 />
			<cfelse>
				<cfset retval.secondary = gray />
			</cfif>
			<cfif scolor3 is not black and scolor3 is not retval.secondary>
				<cfset retval.tertiary = scolor3 />
			<cfelse>
				<cfset retval.tertiary = white />
			</cfif>
		<cfelse>
			<cfset retval.primary = white />
			<cfif scolor2 is not white>
				<cfset retval.secondary = scolor2 />
			<cfelseif scolor3 is not white>
				<cfset retval.secondary = scolor3 />
			<cfelse>
				<cfset retval.secondary = gray />
			</cfif>
			<cfif scolor3 is not white and scolor3 is not retval.secondary>
				<cfset retval.tertiary = scolor3 />
			<cfelse>
				<cfset retval.tertiary = black />
			</cfif>
		</cfif>
		
		<cfreturn retval />
		
	</cffunction>
	
	
	<cffunction name="getBestPrintColors2" access="public" returntype="Struct">
		<cfargument name="pcolor" required="false" default="000000" hint="Product Color" />
		<cfargument name="scolor1" required="false" default="000000" hint="Shop color 1" />
		<cfargument name="scolor2" required="false" default="999999" hint="Shop color 2" />
		<cfargument name="scolor3" required="false" default="FFFFFF" hint="Shop color 3" />
		<cfset var black = '000000' />
		<cfset var gray = '999999' />
		<cfset var white = 'FFFFFF' />
		<cfset var retval = StructNew() />
		<cfset var regularc = 70 />
		<cfset var blackc =  61 />	<!--- black (and white) product contrast does not need to be as high --->
		
		<cfif contrast(scolor1,pcolor) gt regularc or ((pcolor eq '000000' or pcolor eq 'FFFFFF') and contrast(scolor1,pcolor) gt blackc)>
			<cfset retval.primary = scolor1 />
			<cfif (contrast(scolor2,pcolor) gt regularc or ((pcolor eq '000000' or pcolor eq 'FFFFFF') and contrast(scolor2,pcolor) gt blackc)) and (scolor2 neq scolor1)>
				<cfset retval.secondary = scolor2 />
				<cfif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelseif (contrast(scolor3,pcolor) gt regularc or ((pcolor eq '000000' or pcolor eq 'FFFFFF') and contrast(scolor3,pcolor) gt blackc)) and (scolor3 neq scolor1)>
				<cfset retval.secondary = scolor3 />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelseif (contrast(white,pcolor) gt regularc) and (white neq scolor1)>
				<cfset retval.secondary = white />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelse>
					<cfset retval.tertiary = gray />
				</cfif>
			<cfelseif (contrast(black,pcolor) gt regularc) and (black neq scolor1)>
				<cfset retval.secondary = black />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelse>
				<cfset retval.secondary = gray />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif white neq retval.primary and white neq retval.secondary>
					<cfset retval.tertiary = white />
				<cfelse>
					<cfset retval.tertiary = black />
				</cfif>
			</cfif>
		<cfelse>
			<cfset retval.secondary = scolor1 />
			<cfif (contrast(scolor2,pcolor) gt regularc or ((pcolor eq '000000' or pcolor eq 'FFFFFF') and contrast(scolor2,pcolor) gt blackc)) and (scolor2 neq scolor1)>
				<cfset retval.primary = scolor2 />
				<cfif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelseif (contrast(scolor3,pcolor) gt regularc or ((pcolor eq '000000' or pcolor eq 'FFFFFF') and contrast(scolor3,pcolor) gt blackc)) and (scolor3 neq scolor1)>
				<cfset retval.primary = scolor3 />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelseif (contrast(white,pcolor) gt regularc) and (white neq scolor1)>
				<cfset retval.primary = white />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif black neq retval.primary and black neq retval.secondary>
					<cfset retval.tertiary = black />
				<cfelse>
					<cfset retval.tertiary = gray />
				</cfif>
			<cfelseif (contrast(black,pcolor) gt regularc) and (black neq scolor1)>
				<cfset retval.primary = black />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif gray neq retval.primary and gray neq retval.secondary>
					<cfset retval.tertiary = gray />
				<cfelse>
					<cfset retval.tertiary = white />
				</cfif>
			<cfelse>
				<cfset retval.primary = gray />
				<cfif scolor2 neq retval.primary and scolor2 neq retval.secondary>
					<cfset retval.tertiary = scolor2 />
				<cfelseif scolor3 neq retval.primary and scolor3 neq retval.secondary>
					<cfset retval.tertiary = scolor3 />
				<cfelseif white neq retval.primary and white neq retval.secondary>
					<cfset retval.tertiary = white />
				<cfelse>
					<cfset retval.tertiary = black />
				</cfif>
			</cfif>
		</cfif>
		
		<cfreturn retval />
		
	</cffunction>
	
	<cffunction name="contrast" access="private" returntype="numeric">
		<cfargument name="c1" required="false" default="" hint="color 1" />
		<cfargument name="c2" required="false" default="" hint="color 2" />
		<cfset retval = 0 />
		<cfif c1 is not "" and c2 is not "">
			<cfset avc1 = getav(c1) />
			<cfset avc2 = getav(c2) />
			<cfset retval = abs(avc1-avc2) />
		</cfif>
		<cfreturn retval>
	</cffunction>
	
	<cffunction name="getav" access="private" returntype="numeric">
		<cfargument name="hexval" required="false" default="" hint="hex value to get average darkness for" />
		<cfset var retval = 0 />
		<cfset var a = 9 />
		<cfset var b = 10 />
		<cfset var c = 11 />
		<cfset var d = 12 />
		<cfset var e = 13 />
		<cfset var f = 14 />
		<cfif hexval is "EEEEEE">
			<cfset hexval = "FFFFFF" />
		</cfif>
		<cfif Len(hexval) is 6 and REFindNoCase("[^0-9a-fA-F]",hexval) is 0>
			<cfset r1 = IIF(isNumeric(Mid(hexval,1,1)),DE(Mid(hexval,1,1)),Mid(hexval,1,1)) />
			<cfset r2 = IIF(isNumeric(Mid(hexval,2,1)),DE(Mid(hexval,2,1)),Mid(hexval,2,1)) />
			<cfset g1 = IIF(isNumeric(Mid(hexval,3,1)),DE(Mid(hexval,3,1)),Mid(hexval,3,1)) />
			<cfset g2 = IIF(isNumeric(Mid(hexval,4,1)),DE(Mid(hexval,4,1)),Mid(hexval,4,1)) />
			<cfset b1 = IIF(isNumeric(Mid(hexval,5,1)),DE(Mid(hexval,5,1)),Mid(hexval,5,1)) />
			<cfset b2 = IIF(isNumeric(Mid(hexval,6,1)),DE(Mid(hexval,6,1)),Mid(hexval,6,1)) />
			<cfset red = r1*16+r2 />
			<cfset green = g1*16+g2 />
			<cfset blue = b1*16+b2 />
			<cfset retval = Int( (red + green + blue)/3 ) />
		</cfif>
		<cfreturn retval />
	</cffunction>

	</cfcomponent>