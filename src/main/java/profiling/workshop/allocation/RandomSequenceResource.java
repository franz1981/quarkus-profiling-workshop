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
 * Use me with http://localhost:8080/rnd/10
 */
@Path("/rnd/{count}")
public class RandomSequenceResource {

    @Inject
    public RandomGeneratorService rndService;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @NonBlocking
    public String commaSeparatedRandomInts(@PathParam("count") int count) {
        return rndService.generate(count).boxed().map(String::valueOf).collect(Collectors.joining(","));
    }

}
