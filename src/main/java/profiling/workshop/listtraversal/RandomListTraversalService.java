package profiling.workshop.listtraversal;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.PostConstruct;
import javax.inject.Singleton;

@Singleton
public class RandomListTraversalService {

    private static final int LIST_SIZE = 1_000_000;

    private static final List<Integer> indexes = generateIndexes(false);

    private static final List<Integer> values = new ArrayList<>(LIST_SIZE);

    @PostConstruct
    public void initLists() {
        for (int i = 0; i < LIST_SIZE; i++) {
            values.add(i);
        }
    }

    private static List<Integer> generateIndexes(boolean sequential) {
        if (sequential) {
            List<Integer> list = new ArrayList<>();
            for (int i = 0; i < LIST_SIZE; i++) {
                list.add(i);
            }
            return list;
        } else {
            Map<String, Integer> map = new HashMap<>();
            for (int i = 0; i < LIST_SIZE; i++) {
                map.put("" + i, i);
            }
            return new ArrayList<>(map.values());
        }
    }

    public long getResultWithTraversal() {
        long result = 0;
        for (int index : indexes) {
            result += values.get(index);
        }
        return result;
    }
}
