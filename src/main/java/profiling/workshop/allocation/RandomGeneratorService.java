package profiling.workshop.allocation;

import javax.inject.Singleton;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.IntStream;

@Singleton
public class RandomGeneratorService {

    public int next() {
        return ThreadLocalRandom.current().nextInt();
    }

    public IntStream generate(int count) {
        return IntStream.generate(this::next).limit(count);
    }

}
