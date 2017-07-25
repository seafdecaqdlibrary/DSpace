package org.dspace.app.cris.service;

import java.sql.SQLException;
import java.util.UUID;

import org.dspace.app.cris.model.OrganizationUnit;
import org.dspace.core.Context;

public class OrganizationUnitServiceImpl extends CrisObjectServiceImpl<OrganizationUnit> {

	@Override
	public OrganizationUnit find(Context context, UUID id) throws SQLException {
		return getApplicationService().getEntityByUUID(id.toString(), OrganizationUnit.class);
	}

}
