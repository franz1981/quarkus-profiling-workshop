package profiling.workshop.time;

import io.quarkus.scheduler.Scheduled;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.time.ZoneId;
import java.time.format.TextStyle;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

@Path("/time/cached")
public class CachedTimeResource {

    @Inject
    TimeService timeService;

    private static final String ZONE_ID = ZoneId.systemDefault().getDisplayName(TextStyle.FULL, Locale.ITALY);
    private volatile CompletableFuture<Tick> time = new CompletableFuture<>();

    @Scheduled(every = "1s")
    public void updateTime() {
        var tick = new Tick(ZONE_ID, timeService.time());
        if (time.isDone()) {
            time = CompletableFuture.completedFuture(tick);
        } else {
            time.complete(tick);
        }
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public CompletionStage<Tick> now() {
        return time;
    }
}
