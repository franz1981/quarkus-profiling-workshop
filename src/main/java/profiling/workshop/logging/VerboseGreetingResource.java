package profiling.workshop.logging;

import io.smallrye.common.annotation.NonBlocking;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/hello/verbose")
public class VerboseGreetingResource {

    @Inject
    LoggingService log;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public String hello() {
        var msg = "Hello from RESTEasy Reactive";
        log.finest(msg);
        return msg;
    }
}
