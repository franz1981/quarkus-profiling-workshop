package profiling.workshop.logging;

import javax.inject.Singleton;

@Singleton
public class LoggingService {

    private volatile boolean finest;

    public boolean isFinest() {
        return finest;
    }

    public void finest(boolean value) {
        finest = value;
    }

    public void finest(String msg, Object... args) {
        final String formatted = String.format(msg, args);
        if (finest) {
            System.err.println(formatted);
        }
    }
}
