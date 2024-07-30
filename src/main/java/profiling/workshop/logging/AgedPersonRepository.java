package profiling.workshop.logging;

import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import java.time.Year;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Singleton
public class AgedPersonRepository {

    @Inject
    LoggingService log;

    private static final int MAX_AGE = 80;
    private List<Person> persons;

    @PostConstruct
    public void init() {
        final Person[] persons = new Person[MAX_AGE];
        final short oldestBirthYear = (short) (Year.now().getValue() - MAX_AGE);
        for (int i = 0; i < MAX_AGE; i++) {
            final short birthYear = (short) (oldestBirthYear + i);
            persons[i] = new Person(i + 1, UUID.randomUUID().toString(), birthYear);
        }
        this.persons = List.of(persons);
    }

    public Collection<Person> withAgeEqualsTo(int age) {
        final List<Person> sameAgePersons = persons.stream()
                .peek( person -> log.finest("Filtering person %s with age %d", person, person.age()) )
                .filter( person -> person.age() == age )
                .collect(Collectors.toList());

        sameAgePersons.forEach(p -> log.finest("Found person %s with age %d", p, p.age()));
        return sameAgePersons;
    }

}
