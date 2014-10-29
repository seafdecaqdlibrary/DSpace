package org.dspace.app.cris.discovery;

import java.util.List;

import org.apache.solr.common.SolrInputDocument;
import org.dspace.app.cris.integration.RPAuthority;
import org.dspace.content.DCValue;
import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.content.authority.ChoiceAuthorityManager;
import org.dspace.content.authority.Choices;
import org.dspace.core.Context;
import org.dspace.discovery.SolrServiceIndexPlugin;

public class PendingMatchSolrIndexer implements SolrServiceIndexPlugin
{

    @Override
    public void additionalIndex(Context context, DSpaceObject dso,
            SolrInputDocument document)
    {

        if (dso instanceof Item)
        {
            Item item = (Item) dso;

            List<String> listMetadata = ChoiceAuthorityManager.getManager()
                    .getAuthorityMetadataForAuthority(
                            RPAuthority.RP_AUTHORITY_NAME);

            for (String metadata : listMetadata)
            {
                DCValue[] values = item.getMetadata(metadata);
                for (DCValue val : values)
                {
                    if (val != null)
                    {
                        if (val.authority != null && !(val.authority.isEmpty()))
                        {
                            if (val.confidence != Choices.CF_ACCEPTED)
                            {
                                document.addField("authority." + RPAuthority.RP_AUTHORITY_NAME + "." + metadata +".pending", val.authority);
                            }
                        }
                    }
                }
            }

        }

    }

}

