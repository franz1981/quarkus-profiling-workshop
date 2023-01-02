package profiling.workshop.listtraversal;

import java.time.ZoneId;
import java.time.format.TextStyle;
import java.util.Locale;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.quarkus.runtime.annotations.RegisterForReflection;
import profiling.workshop.time.TimeService;

@Path("/list")
public class ListTraversalResource {

    @Inject
    ListTraversalService service;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public long processList() {
        return service.getResultWithTraversal();
    }
}
