/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.rest.submit.factory.impl;

import java.sql.SQLException;

import org.dspace.app.rest.model.MetadataValueRest;
import org.dspace.content.WorkspaceItem;
import org.dspace.content.service.ItemService;
import org.dspace.core.Context;
import org.dspace.core.Utils;
import org.dspace.services.model.Request;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.rest.webmvc.json.patch.LateObjectEvaluator;

/**
 * Submission "add" operation to add metadata in the Item
 * 
 * @author Luigi Andrea Pascarelli (luigiandrea.pascarelli at 4science.it)
 *
 */
public class ItemMetadataValueAddPatchOperation extends AddPatchOperation<MetadataValueRest> {

	@Autowired
	ItemService itemService;
	
	@Override
	void add(Context context, Request currentRequest, WorkspaceItem source, String path, Object value) throws Exception {
		String[] split = path.split("/");
		addValue(context, source, split[0], evaluateObject((LateObjectEvaluator)value));
	}

	@Override
	protected Class<MetadataValueRest[]> getClassForEvaluation() {
		return MetadataValueRest[].class;
	}

	private void addValue(Context context, WorkspaceItem source, String target, MetadataValueRest[] list) throws SQLException {
		String[] metadata = Utils.tokenize(target);
		for(MetadataValueRest ll : list) {
			itemService.addMetadata(context, source.getItem(), metadata[0], metadata[1], metadata[2], ll.getLanguage(), ll.getValue(), ll.getAuthority(), ll.getConfidence());
		}
	}
}