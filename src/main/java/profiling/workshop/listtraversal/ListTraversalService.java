package profiling.workshop.listtraversal;

import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import javax.annotation.PostConstruct;
import javax.inject.Singleton;

@Singleton
public class ListTraversalService {
    private List<Integer> myList;

    @PostConstruct
    public void initList() {
        myList = new LinkedList<>();
        for (int i = 0; i < 1024; i++) {
            myList.add(ThreadLocalRandom.current().nextInt(0, Integer.MAX_VALUE));
        }
    }

    public long sum() {
        int sum = 0;
        for (int i = 0; i < myList.size(); i++) {
            sum += myList.get(i);
        }
        return sum;
    }
}
