package profiling.workshop.logging;

import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
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

    public void finest(String... msgs) {
        final String formatted = String.format("This is finest: [%s]", msgs);
        if (finest) {
            System.err.println(formatted);
        }
    }
}
