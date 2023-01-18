package profiling.workshop.listtraversal;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Stream;
import javax.annotation.PostConstruct;
import javax.inject.Singleton;

@Singleton
public class PersonsTraversalService {

    private static final int LIST_SIZE = 10_000;

    private List<Person> persons;

    @PostConstruct
    public void initLists() {
        persons = new LinkedList<>();
        Stream.iterate(0, i -> i < LIST_SIZE, i -> i+1)
                .forEach(i -> persons.add(Person.randomPerson()));
    }

    public int getAgeSum() {
        return persons.stream().mapToInt(Person::getAge).sum();
    }

}
