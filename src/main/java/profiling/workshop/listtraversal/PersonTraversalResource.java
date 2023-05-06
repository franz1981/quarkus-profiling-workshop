package profiling.workshop.listtraversal;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

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
