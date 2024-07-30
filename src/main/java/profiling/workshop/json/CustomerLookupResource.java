package profiling.workshop.json;

import java.util.ArrayList;
import java.util.List;

import io.smallrye.common.annotation.NonBlocking;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/customer")
public class CustomerLookupResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @NonBlocking
    public Customer hello() {
        return CustomerHolder.DEFAULT_CUSTOMER;
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/empty")
    @NonBlocking
    public Empty empty() {
        return new Empty();
    }

    private static class CustomerHolder {

        private static final Customer DEFAULT_CUSTOMER = createCustomer();

        private static Customer createCustomer() {
            Customer customer = new Customer();
            customer.setFirstName("Mario");
            customer.setLastName("Fusco");
            customer.setAge(50);
            customer.setIncome(1000.0);

            Address address = new Address();
            address.setTown("Mondragone");
            address.setStreet("viale Michelangelo");
            customer.setAddress(address);

            List<Person> children = new ArrayList<>();
            children.add(new Person("Sofia", "Fusco", 12));
            children.add(new Person("Marilena", "Fusco", 9));
            customer.setChildren(children);

            customer.setCreditCards(new CreditCard[]{ new CreditCard("Visa", 100.0), new CreditCard("Amex", 150.0) });

            return customer;
        }
    }
}
