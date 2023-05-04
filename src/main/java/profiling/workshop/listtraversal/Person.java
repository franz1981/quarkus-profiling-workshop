package profiling.workshop.listtraversal;

import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

public record Person(String name, int age, byte[] avatarImage) {

    public static Person randomPerson() {
        String name = UUID.randomUUID().toString();
        int age = ThreadLocalRandom.current().nextInt(0, 120);
        byte[] avatar = new byte[1000];
        ThreadLocalRandom.current().nextBytes(avatar);
        return new Person(name, age, avatar);
    }
}
