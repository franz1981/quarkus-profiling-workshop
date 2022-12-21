#!/bin/bash

# let's run it with a single thread, is simpler!
# TODO cmd can be extracted and become a run-quarkus.sh script per-se
java -Dquarkus.vertx.event-loops-pool-size=1 -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
quarkus_pid=$!

sleep 2

echo "Quarkus running at pid $quarkus_pid"

echo "Warming-up endpoint"

# warm it up, it's fine if it's blocking and max speed

hyperfoil-0.23/bin/wrk.sh -c 10 -t 1 -d 10s http://localhost:8080/hello

echo "Warmup completed: start test and profiling"

hyperfoil-0.23/bin/wrk.sh -c 10 -t 1 -d 10s http://localhost:8080/hello &

wrk_pid=$!

sleep 4

java -jar ap-loader-all.jar profiler -e cpu -d 5 -f $quarkus_pid.html $quarkus_pid &

wait $!

wait $wrk_pid

echo "Profiling and workload completed: killing server"

kill -SIGTERM $quarkus_pid


