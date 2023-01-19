package profiling.workshop.logging;

import io.smallrye.common.annotation.NonBlocking;
import profiling.workshop.logging.AgedPersonRepository.Person;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.util.Collection;

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
