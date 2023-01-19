package profiling.workshop.allocation;

import io.smallrye.common.annotation.NonBlocking;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.util.stream.Collectors;


/**
 * Use me with http://localhost:8080/fast-rnd/10
 */
@Path("/fast-rnd/{count}")
public class FastRandomSequenceResource {

    @Inject
    public RandomGeneratorService rndService;
    @Inject
    public StringBuilderPool pool;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public String fastCommaSeparatedRandomInts(@PathParam("count") int count) {
        if (count == 0) {
            return "";
        }
        var tmp = pool.acquire();
        tmp.append(rndService.next());
        for (int i = 1; i < count; i++) {
            tmp.append(',').append(rndService.next());
        }
        return tmp.toString();
    }

}
