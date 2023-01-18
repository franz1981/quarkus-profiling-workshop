package profiling.workshop.listtraversal;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.smallrye.common.annotation.NonBlocking;

@Path("/persons/agesum")
public class PersonTraversalResource {

    @Inject
    PersonsTraversalService service;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public int sum() {
        return service.getAgeSum();
    }
}
