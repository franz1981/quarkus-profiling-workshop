package profiling.workshop.logging;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import javax.inject.Singleton;

@Singleton
public class LoggingService {

    private static Logger logger = Logger.getLogger(LoggingService.class.getName());

    static {
        ConsoleHandler handler = new ConsoleHandler();
        handler.setFormatter(new MyFormatter());
        logger.addHandler(handler);
    }

    public void log(String msg) {
        logger.log(Level.SEVERE, String.format("Your var is [%s] and you are [%s]", "uno", "due"));
    }

    public static void main(String[] args) {
        new LoggingService().log("test");
    }

    private static class MyFormatter extends SimpleFormatter {
        @Override
        public String format(LogRecord record) {
            return super.format(record);
        }
    }
}
