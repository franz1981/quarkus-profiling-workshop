package profiling.workshop.time;

import io.quarkus.scheduler.Scheduled;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
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
    private volatile CompletableFuture<TimeResource.Tick> time = new CompletableFuture<>();

    @Scheduled(every = "1s")
    public void updateTime() {
        var tick = new TimeResource.Tick(ZONE_ID, timeService.time());
        if (time.isDone()) {
            time = CompletableFuture.completedFuture(tick);
        } else {
            time.complete(tick);
        }
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public CompletionStage<TimeResource.Tick> now() {
        return time;
    }
}
