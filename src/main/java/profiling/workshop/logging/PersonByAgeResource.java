package profiling.workshop.logging;

import io.smallrye.common.annotation.NonBlocking;
import profiling.workshop.logging.AgedPersonRepository.Person;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.Collection;

/**
 * Use me with http://localhost:8080/persons/age/42
 */
@Path("/persons/age/{age}")
public class PersonByAgeResource {

    @Inject
    AgedPersonRepository agedPersonRepository;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @NonBlocking
    public Collection<Person> listByAge(@PathParam("age") int age) {
        return agedPersonRepository.withAgeEqualsTo(age);
    }
}
