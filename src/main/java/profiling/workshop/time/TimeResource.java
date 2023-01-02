package profiling.workshop.time;

import io.quarkus.runtime.annotations.RegisterForReflection;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.time.ZoneId;
import java.time.format.TextStyle;
import java.util.Locale;

@Path("/time")
public class TimeResource {

    @Inject
    TimeService service;

    @RegisterForReflection
    public record Tick(String zoneId, long utcTime) { }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Tick now() {
        return new Tick(ZoneId.systemDefault().getDisplayName(TextStyle.FULL, Locale.ITALY), service.time());
    }
}
