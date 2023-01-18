package profiling.workshop.listtraversal;

import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.random.RandomGenerator;

public class Person {

    private final String name;

    private final int age;

    private final byte[] avatarImage;

    public Person(String name, int age, byte[] avatarImage) {
        this.name = name;
        this.age = age;
        this.avatarImage = avatarImage;
    }

    public String getName() {
        return name;
    }

    public int getAge() {
        return age;
    }

    public byte[] getAvatarImage() {
        return avatarImage;
    }

    public static Person randomPerson() {
        String name = UUID.randomUUID().toString();
        int age = ThreadLocalRandom.current().nextInt(0, 120);
        byte[] avatar = new byte[1000];
        ThreadLocalRandom.current().nextBytes(avatar);
        return new Person(name, age, avatar);
    }
}
