package profiling.workshop.listtraversal;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import javax.annotation.PostConstruct;
import javax.inject.Singleton;

@Singleton
public class LinkedListTraversalService {

    private static final int BUCKETS = 16;

    private static final int LIST_SIZE = 1_000_000;

    private static final List<Integer>[] lists = new List[BUCKETS];

    @PostConstruct
    public void initLists() {
        for (int i = 0; i < BUCKETS; i++) {
            lists[i] = new LinkedList<>();
//            lists[i] = new ArrayList<>(LIST_SIZE);
        }

        for (int i = 0; i < BUCKETS * LIST_SIZE; i++) {
            lists[i % BUCKETS].add(i);
        }
    }

    public long getResultWithTraversal() {
        long result = 0;
        for (int i : lists[0]) {
            result += i;
        }
        return result;
    }

}
