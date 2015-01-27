<cfif !hasDesigns>
	<div id="no-designs-info" class="alert alert-info" role="alert">
		<span class="glyphicon glyphicon-info-sign"></span>
        <strong>You have not selected any design folders.</strong> The API will default to all MyLocker design categories.
      </div>
</cfif>
<!----<div class="row">
	<div class="panel panel-default">
		<div class="panel-heading">
			<h3 class="panel-title">Design Options:</h3>
		</div>
		<div class="panel-body">

			<label><input type="checkbox" name="myUploadedDesigns" id="myUploadedDesigns" <cfif ShowOnlyMyDesigns> checked</cfif> /> Display only my uploaded logos and designs</label>
			<div id="myUploadedDesignsSaved"></div>
			<div id="logo-uploads">
				Uploaded Designs/Logos
			</div>
		</div>
	</div>
</div>----->
<div id="design-selection" class="row">
	<p>
		Drag and Drop the Design Folders or Activities from MyLocker to My Designs to control the design options that show on your site.
	</p>
	<br />
	<div class="col-xs-6">
		<div class="tree ">
			<strong>MyLocker Design Categories:</strong>
			<ul class="mylocker-designs">
			<cfoutput query="designCategories">
				<li>
					<span data-list="mylocker" data-level="group" data-group-id="#cat_id#" data-item="#cat_id#" data-loaded="0"><i class="glyphicon glyphicon-folder-close" style="color:##CCAB26;"></i> #description#</span>
					<ul id="mylocker_group_#cat_id#">
		                <li style="display:none">
		                	<span><i class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></i> Loading</span>
						</li>
					</ul>
				</li>
			</cfoutput>
			</ul>
		</div>
	</div>
	<div class="col-xs-4 affix" style="left:58%;overflow-y:auto;height:100%;padding-bottom:100px">
		<div class="tree ">
			<strong>My Design Categories:</strong>

			<cfif !hasDesigns>
				<ul class="my-designs" style="min-height:112px">

				</ul>
			<cfelse>
				<ul class="my-designs" style="min-height:112px">
				<cfoutput query="myDesignCategories">
					<li>
						<span data-list="my" data-level="group" data-item="#cat_id#" data-loaded="0"><i class="glyphicon glyphicon-folder-close" style="color:##CCAB26;"></i> #description#</span>
						<a data-toggle="confirmation" data-placement="top" onConfirm="deleteDesign('group',#cat_id#,#cat_id#);">
							<i class="glyphicon glyphicon-remove" aria-hidden="true"></i>
						</a>
						<ul id="my_group_#cat_id#">
			                <li style="display:none">
			                	<span><i class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></i> Loading</span>
							</li>
						</ul>
					</li>
				</cfoutput>
				</ul>
			</cfif>
		</div>
	</div>
</div>