package profiling.workshop;

import io.quarkus.scheduler.Scheduled;
import io.smallrye.mutiny.Uni;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.time.ZoneId;
import java.time.format.TextStyle;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;

@Path("/sampled")
public class SampleTimeResource {

    @Inject
    private TimeService timeService;

    private volatile long time;

    private static final String ZONE_ID = ZoneId.systemDefault().getDisplayName(TextStyle.FULL, Locale.ITALY);
    private CompletableFuture<Boolean> firstTime = new CompletableFuture<>();

    @Scheduled(every = "1s")
    public void updateTime() {
        time = timeService.time();
        firstTime.complete(Boolean.TRUE);
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<TimeResource.Tick> now() {
        if (firstTime.isDone()) {
            return Uni.createFrom().item(new TimeResource.Tick(ZONE_ID, time));
        }
        return Uni.createFrom()
                .completionStage(firstTime)
                .map(ignore -> new TimeResource.Tick(ZoneId.systemDefault()
                        .getDisplayName(TextStyle.FULL, Locale.ITALY), time));
    }
}
