package profiling.workshop.allocation;

import io.smallrye.common.annotation.NonBlocking;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
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
