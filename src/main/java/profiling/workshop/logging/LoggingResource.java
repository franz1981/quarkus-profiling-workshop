package profiling.workshop.logging;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import profiling.workshop.listtraversal.ListTraversalService;

@Path("/log")
public class LoggingResource {

    @Inject
    LoggingService service;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public void log() {
        service.log("test");
    }
}
