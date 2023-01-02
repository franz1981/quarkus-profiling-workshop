package profiling.workshop.listtraversal;

import io.smallrye.common.annotation.NonBlocking;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/sum")
public class ListTraversalResource {

    @Inject
    ListTraversalService service;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public long sum() {
        return service.sum();
    }
}
