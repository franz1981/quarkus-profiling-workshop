#!/bin/bash

HYPERFOIL_HOME=./hyperfoil-0.24

URL=hello

DURATION=20

EVENT=cpu

# this can be html or jfr
FORMAT=html

JFR=false

THREADS=1

RATE=0

CONNECTIONS=10

JFR_ARGS=

PERF=false

while getopts ":u::e::f::d::j::t::r::c:p" option; do
   case $option in
      u) URL=${OPTARG}
         ;;
      e) EVENT=${OPTARG}
         ;;
      f) FORMAT=${OPTARG}
         ;;
      d) DURATION=${OPTARG}
         ;;
      j) JFR=${OPTARG}
         ;;
      t) THREADS=${OPTARG}
         ;;
      r) RATE=${OPTARG}
         ;;
      c) CONNECTIONS=${OPTARG}
         ;;
      p) PERF=true
         ;;
   esac
done

WARMUP=$((${DURATION}*2/5))

PROFILING=$((${DURATION}/2))

FULL_URL=http://localhost:8080/${URL}

echo "Benchmarking endpoint ${FULL_URL}"

# set sysctl kernel variables only if necessary
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  current_value=$(sysctl -n kernel.perf_event_paranoid)
  if [ "$current_value" -ne 1 ]; then
    sudo sysctl kernel.perf_event_paranoid=1
    sudo sysctl kernel.kptr_restrict=0
  fi
fi

if [ "${JFR}" = true ]; then
   JFR_ARGS=-XX:+FlightRecorder
fi

trap 'echo "cleaning up quarkus process";kill ${quarkus_pid}' SIGINT SIGTERM SIGKILL

# let's run it with a single thread, is simpler!
# TODO cmd can be extracted and become a run-quarkus.sh script per-se
java ${JFR_ARGS} -Dquarkus.vertx.event-loops-pool-size=${THREADS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
quarkus_pid=$!

sleep 2

echo "Quarkus running at pid $quarkus_pid using ${THREADS} I/O threads"

echo "Warming-up endpoint"

# warm it up, it's fine if it's blocking and max speed

${HYPERFOIL_HOME}/bin/wrk.sh -c 10 -t 1 -d ${DURATION}s ${FULL_URL}

if [ "${RATE}" != "0" ]
then
  echo "Warmup completed: start fixed rate test at ${RATE} requests/sec and profiling"
  ${HYPERFOIL_HOME}/bin/wrk2.sh -R ${RATE} -c ${CONNECTIONS} -t 1 -d ${DURATION}s ${FULL_URL} &
else
  echo "Warmup completed: start all-out test and profiling"
  ${HYPERFOIL_HOME}/bin/wrk.sh -c ${CONNECTIONS} -t 1 -d ${DURATION}s ${FULL_URL} &
fi

wrk_pid=$!

echo "Waiting $WARMUP seconds before profiling for $PROFILING seconds"

sleep $WARMUP

if [ "${JFR}" = true ]
then
  jcmd $quarkus_pid JFR.start duration=${PROFILING}s filename=${quarkus_pid}.jfr dumponexit=true settings=profile
else
  echo "Starting async-profiler on $quarkus_pid"
  java -jar ap-loader-all.jar profiler -e ${EVENT} -t -d ${PROFILING} -f ${quarkus_pid}_${EVENT}.${FORMAT} $quarkus_pid &
fi

ap_pid=$!

if [ "${PERF}" = true ]; then
  echo "Starting perf stat on $quarkus_pid"
  perf stat -d -p $quarkus_pid &
  stat_pid=$!
fi

echo "Showing pidstat for $WARMUP seconds"

pidstat -p $quarkus_pid 1 &

pidstat_pid=$!

sleep $WARMUP

kill -SIGTERM $pidstat_pid

echo "Stopping pidstat, waiting load to complete"

wait $ap_pid

if [ "${PERF}" = true ]; then
  kill -SIGINT $stat_pid
fi

wait $wrk_pid

echo "Profiling and workload completed: killing server"

kill -SIGTERM $quarkus_pid
