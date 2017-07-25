package org.dspace.app.cris.service;

import java.sql.SQLException;
import java.util.UUID;

import org.dspace.app.cris.model.ACrisObject;
import org.dspace.app.cris.model.CrisConstants;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.service.RootEntityService;
import org.dspace.core.Context;
import org.springframework.beans.factory.annotation.Autowired;

public abstract class CrisObjectServiceImpl<T extends ACrisObject> implements RootEntityService<T> {
	
	private ApplicationService applicationService;
	
	@Override
	public void updateLastModified(Context context, T dSpaceObject) throws SQLException, AuthorizeException {
		// nothing		
	}

	@Override
	public boolean isSupportsTypeConstant(int type) {
		if(CrisConstants.CRIS_DYNAMIC_TYPE_ID_START >= type) {
			return true;
		}
		return false;
	}

	public ApplicationService getApplicationService() {
		return applicationService;
	}

	public void setApplicationService(ApplicationService applicationService) {
		this.applicationService = applicationService;
	}

}
