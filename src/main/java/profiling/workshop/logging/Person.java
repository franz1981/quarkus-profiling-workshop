package profiling.workshop.logging;

import java.time.Year;

public record Person(long id, String name, short birthYear) {

    int age() {
        return Year.now().getValue() - birthYear;
    }

}