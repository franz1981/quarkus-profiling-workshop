package profiling.workshop.time;

import jakarta.inject.Singleton;
import java.util.OptionalLong;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

@Singleton
public class TimeService {

    public TimeService() {

    }

    private final Semaphore maxConcurrentRequests = new Semaphore(4);

    public long time() {
        maxConcurrentRequests.acquireUninterruptibly();
        try {
            TimeUnit.MILLISECONDS.sleep(10L);
        } catch (Throwable ignore) {
            //
        }
        try {
            return System.currentTimeMillis();
        } finally {
            maxConcurrentRequests.release();
        }
    }
}
