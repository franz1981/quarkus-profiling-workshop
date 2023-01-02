package profiling.workshop.listtraversal;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import javax.inject.Singleton;

@Singleton
public class ListTraversalService {

    private static final List<Integer> MY_LIST = new ArrayList<>();

    static {
        for (int i = 0; i < 10_000_000; i++) {
            MY_LIST.add(i);
        }
    }

    public long getResultWithPositionalAccess() {
        int result = 0;
        for (int i = 0; i < MY_LIST.size(); i++) {
            if (i % 16 == 0) {
                result += MY_LIST.get(i);
            }
        }
        return result;
    }

    public long getResultWithTraversal() {
        long result = 0;
        int i = 0;
        for (int item : MY_LIST) {
//            if (i % 16 == 0) {
            if ((i & 15) == 0) {
                result += item;
            }
            i++;
        }
        return result;
    }

    public static void main(String[] args) {
        ListTraversalService service = new ListTraversalService();
        long start = System.nanoTime();
        long result = service.getResultWithTraversal();
        long duration = (System.nanoTime() - start) / 1_000_000;
        System.out.println(result + " calculated in " + duration + " msecs");
    }
}
