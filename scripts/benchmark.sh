#!/bin/bash

URL=hello

DURATION=40

EVENT=cpu

# this can be html or jfr
FORMAT=html

JFR=false

THREADS=2

RATE=0

CONNECTIONS=10

JFR_ARGS=

PERF=false

WRK_PROFILING=false

TOTAL=false

die () {
    echo "$*"
    exit 1
}

Help()
{
   # Display Help
   echo "Syntax: benchmark [OPTIONS]"
   echo "options:"
   echo "h    Display this guide."
   echo ""
   echo "u    Final part of the URL to benchmark."
   echo "     e.g. benchmark -u time would benchmark http://localhost:8080/time"
   echo "     default is hello"
   echo ""
   echo "e    event to profile, if supported e.g. -e cpu "
   echo "     check https://github.com/jvm-profiling-tools/async-profiler#profiler-options for the complete list"
   echo "     default is cpu"
   echo ""
   echo "f    output format, if supported by the profiler. e.g. async-profiler support html,jfr,collapsed"
   echo "     default is html"
   echo ""
   echo "d    duration of the load generation phase, in seconds"
   echo "     default is 20"
   echo ""
   echo "j    if specified, it uses JFR profiling. async-profiler otherwise."
   echo ""
   echo "t    number of I/O threads of the quarkus application."
   echo ""
   echo "     default is 2"
   echo ""
   echo "r    rate of the load generation phase, in requests/sec."
   echo "     default not specified (0)"
   echo ""
   echo "c    number of connections used by the load generator."
   echo "     default is 10"
   echo ""
   echo "p    if specified, run perf stat together with the selected profiler. Only GNU Linux."
   echo ""
   echo "w    profile the load generator, Hyperfoil in this case."
   echo "     default is false"
   echo ""
   echo "g    if specified, run async-profiler with the --total flag."
   echo "     default is false"
}

while getopts "hu:e:f:d:jt:r:c:pwg" option; do
   case $option in
      h) Help
         exit;;
      u) URL=${OPTARG}
         ;;
      e) EVENT=${OPTARG}
         ;;
      f) FORMAT=${OPTARG}
         ;;
      d) DURATION=${OPTARG}
         ;;
      j) JFR=true
         ;;
      t) THREADS=${OPTARG}
         ;;
      r) RATE=${OPTARG}
         ;;
      c) CONNECTIONS=${OPTARG}
         ;;
      p) PERF=true
         ;;
      w) WRK_PROFILING=true
         ;;
      g) TOTAL=true
         ;;
      *) echo "Invalid option: -${OPTARG}"; Help; exit 1;;
   esac
done

if ! [[ -f benchmark.sh ]]; then
    die "error: should be run from the scripts/ directory"
fi

WARMUP=$((${DURATION}*2/5))

PROFILING=$((${DURATION}/2))

FULL_URL=http://localhost:8080/${URL}

echo "----- Install ap-loader -----"

jbang app install ap-loader@jvm-profiling-tools/ap-loader

echo "----- Install Hyperfoil -----"

jbang app install wrk2@hyperfoil

jbang app install wrk@hyperfoil

echo "----- Benchmarking endpoint ${FULL_URL}"

# set sysctl kernel variables only if necessary
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  current_value=$(sysctl -n kernel.perf_event_paranoid)
  if [ "$current_value" -ne 1 ]; then
    echo "----- Setting kernel params Linux Perf usage"
    sudo sysctl kernel.perf_event_paranoid=1
    sudo sysctl kernel.kptr_restrict=0
  fi
fi

if [ "${JFR}" = true ]; then
   JFR_ARGS=-XX:+FlightRecorder
fi

trap 'echo "cleaning up quarkus process"; kill ${quarkus_pid} 2>/dev/null || true' SIGINT SIGTERM EXIT

# let's run it with a single thread, is simpler!
# TODO cmd can be extracted and become a run-quarkus.sh script per-se
# you can tune the worker pool as well via -Dquarkus.thread-pool.max-threads=1
java ${JFR_ARGS} -Dquarkus.vertx.event-loops-pool-size=${THREADS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
quarkus_pid=$!

sleep 2

echo "----- Quarkus running at pid $quarkus_pid using ${THREADS} I/O threads"

if [ "${RATE}" != "0" ]
then
  echo "----- Start fixed rate test at ${RATE} requests/sec and profiling"
  jbang wrk2@hyperfoil -R ${RATE} -c ${CONNECTIONS} -t ${THREADS} -d ${DURATION}s ${FULL_URL} &
else
  echo "----- Start all-out test and profiling"
 jbang wrk@hyperfoil -c ${CONNECTIONS} -t ${THREADS} -d ${DURATION}s ${FULL_URL} &
fi

wrk_pid=$!

echo "----- Waiting $WARMUP seconds before profiling for $PROFILING seconds"

sleep $WARMUP

NOW=$(date "+%y%m%d_%H_%M_%S")

# compute profiler total argument
TOTAL_ARG=""
if [ "${TOTAL}" = true ]; then
  TOTAL_ARG="--total"
fi

if [ "${JFR}" = true ]
then
  jcmd $quarkus_pid JFR.start duration=${PROFILING}s filename=${NOW}.jfr dumponexit=true settings=profile
else
  if [ "${WRK_PROFILING}" = true ]; then
     JFR_ARGS=-XX:+FlightRecorder
     wrk_jvm_pid=`jps | grep Wrk | awk '{print $1}'`
     echo "----- Starting async-profiler on load generator process ($wrk_jvm_pid)"
     jbang ap-loader@jvm-profiling-tools/ap-loader profiler ${TOTAL_ARG} -e ${EVENT} -t -d ${PROFILING} -f wrk_${NOW}_${EVENT}.${FORMAT} $wrk_jvm_pid &
  fi
  echo "----- Starting async-profiler on quarkus application ($quarkus_pid)"
  jbang ap-loader@jvm-profiling-tools/ap-loader profiler ${TOTAL_ARG} -e ${EVENT} -t -d ${PROFILING} -f ${NOW}_${EVENT}.${FORMAT} $quarkus_pid &
fi

ap_pid=$!

if [ "${PERF}" = true ]; then
  if [ "${WRK_PROFILING}" = true ]; then
    echo "----- Collecting perf stat on $wrk_jvm_pid"
    perf stat -d -p "$wrk_jvm_pid" sleep ${PROFILING} &
  fi
  echo "----- Collecting perf stat on $quarkus_pid"
  perf stat -d -p $quarkus_pid sleep ${PROFILING} &
fi

echo "----- Showing stats for $WARMUP seconds"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  pidstat -p $quarkus_pid 1 &
  pidstat_pid=$!
  sleep $WARMUP
  kill -SIGTERM "$pidstat_pid"
else
  # Print stats header
  ps -p $quarkus_pid -o %cpu,rss,vsz | head -1
  sleep 1;
  # Print stats
  for (( i=1; i<$WARMUP; i++ )); do ps -p $quarkus_pid -o %cpu,rss,vsz | tail -1;sleep 1;done;
fi

echo "----- Stopped stats, waiting load to complete"

wait $ap_pid

wait $wrk_pid

echo "----- Profiling and workload completed: killing server"

kill -SIGTERM $quarkus_pid
