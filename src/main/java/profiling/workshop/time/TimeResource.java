package profiling.workshop.time;

import io.quarkus.runtime.annotations.RegisterForReflection;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
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
