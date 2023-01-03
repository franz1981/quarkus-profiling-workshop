package profiling.workshop.listtraversal;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.smallrye.common.annotation.NonBlocking;

@Path("/list/random")
public class RandomListTraversalResource {

    @Inject
    RandomListTraversalService service;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public long sum() {
        return service.getResultWithTraversal();
    }
}
