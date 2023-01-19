package profiling.workshop.allocation;

import io.vertx.core.Context;

import javax.inject.Singleton;

@Singleton
public class StringBuilderPool {

    private static final int DEFAULT_INITIAL_CAPACITY = 128 * 1024;
    private static final ThreadLocal<StringBuilder> BUILDER_POOL = ThreadLocal.withInitial(() -> new StringBuilder(DEFAULT_INITIAL_CAPACITY));

    public StringBuilder acquire() {
        if (!Context.isOnEventLoopThread()) {
            throw new IllegalStateException("this cannot be used outside the event loop thread");
        }
        var pooled = BUILDER_POOL.get();
        if (pooled == null) {
            return new StringBuilder(DEFAULT_INITIAL_CAPACITY);
        } else {
            pooled.setLength(0);
        }
        BUILDER_POOL.set(null);
        return pooled;
    }

    public void release(StringBuilder used) {
        if (!Context.isOnEventLoopThread()) {
            throw new IllegalStateException("this cannot be used outside the event loop thread");
        }
        BUILDER_POOL.set(used);
    }


}
