#!/bin/bash

HYPERFOIL_HOME=./hyperfoil

URL=hello

DURATION=40

EVENT=cpu

# this can be html or jfr
FORMAT=html

JFR=false

THREADS=1

RATE=0

CONNECTIONS=20

PIPELINING=1

JFR_ARGS=

PERF=false

# partially disable inflation: move to JDK 17 and use -Dsun.reflect.inflationThreshold=2147483647

QUARKUS_JVM_ARGS="-Dquarkus.vertx.prefer-native-transport=true"

OPT_QUARKUS_JVM_ARGS="-Dquarkus.http.limits.max-body-size= \
                   -Dquarkus.vertx.prefer-native-transport=true  \
                   -XX:-StackTraceInThrowable \
                   -Dquarkus.http.accept-backlog=-1 \
                   -Dio.netty.buffer.checkBounds=false \
                   -Dio.netty.buffer.checkAccessible=false \
                   -Djava.util.logging.manager=org.jboss.logmanager.LogManager \
                   -Dquarkus.http.idle-timeout=0 \
                   -XX:+UseNUMA \
                   -XX:+UseParallelGC \
                   -Djava.lang.Integer.IntegerCache.high=10000 \
                   -Dvertx.disableURIValidation=true \
                   -Dvertx.disableHttpHeadersValidation=true \
                   -Dvertx.disableMetrics=true \
                   -Dvertx.disableH2c=true \
                   -Dvertx.disableWebsockets=true \
                   -Dvertx.flashPolicyHandler=false \
                   -Dvertx.threadChecks=false \
                   -Dvertx.disableContextTimings=true \
                   -Dhibernate.allow_update_outside_transaction=true \
                   -Dio.quarkus.vertx.core.runtime.context.VertxContextSafetyToggle.I_HAVE_CHECKED_EVERYTHING=true \
                   -Djboss.threads.eqe.statistics=false \
                   -Dmutiny.disableCallBackDecorators=true"

HTTP_2=false

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
   echo "     default is 1"
   echo ""
   echo "r    rate of the load generation phase, in requests/sec."
   echo "     default not specified (0)"
   echo ""
   echo "c    number of connections used by the load generator."
   echo "     default is 10"
   echo ""
   echo "p    if specified, run perf stat together with the selected profiler. Only GNU Linux."
}

while getopts "hu::e::f::d::jt::r::c::m:p" option; do
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
      m) PIPELINING=${OPTARG}
         ;;
      p) PERF=true
         ;;
   esac
done

WARMUP=$((${DURATION}*2/5))

PROFILING=$((${DURATION}/2))

FULL_URL=http://localhost:8080/${URL}

echo "----- Benchmarking endpoint ${FULL_URL}"

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
java ${JFR_ARGS} -Dquarkus.vertx.event-loops-pool-size=${THREADS} ${QUARKUS_JVM_ARGS} -jar ../target/quarkus-app/quarkus-run.jar &
quarkus_pid=$!

sleep 2

echo "----- Quarkus running at pid $quarkus_pid using ${THREADS} I/O threads"

if [ "${RATE}" != "0" ]
then
  echo "----- Start fixed rate test at ${RATE} requests/sec and profiling"
  if [ "${HTTP_2}" = true ]
  then
    h2load ${FULL_URL} -c ${CONNECTIONS} -D ${DURATION}s -t ${THREADS} -m ${PIPELINING} -r {RATE} &
  else
    h2load ${FULL_URL} -c ${CONNECTIONS} -D ${DURATION}s -t ${THREADS} -m ${PIPELINING} -r {RATE} --h1 &
  fi
else
  echo "----- Start all-out test and profiling"
  if [ "${HTTP_2}" = true ]
    then
      h2load ${FULL_URL} -c ${CONNECTIONS} -D ${DURATION}s -t ${THREADS} -m ${PIPELINING} &
    else
      h2load ${FULL_URL} -c ${CONNECTIONS} -D ${DURATION}s -t ${THREADS} -m ${PIPELINING} --h1 &
    fi
fi

load_generation_pid=$!

echo "----- Waiting $WARMUP seconds before profiling for $PROFILING seconds"

sleep $WARMUP

NOW=$(date "+%y%m%d_%H_%M_%S")

if [ "${JFR}" = true ]
then
  jcmd $quarkus_pid JFR.start duration=${PROFILING}s filename=${NOW}.jfr dumponexit=true settings=profile
else
  echo "----- Starting async-profiler on quarkus application ($quarkus_pid)"
  java -jar ap-loader-all.jar profiler -e ${EVENT} -d ${PROFILING} -t -f ${NOW}_${EVENT}.${FORMAT} $quarkus_pid &
fi

ap_pid=$!

if [ "${PERF}" = true ]; then
  echo "----- Collecting perf stat on $quarkus_pid"
  perf stat -d -p $quarkus_pid &
  stat_pid=$!
fi

echo "----- Showing stats for $WARMUP seconds"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  pidstat -p $quarkus_pid 1 &
  pidstat_pid=$!
  sleep $WARMUP
  kill -SIGTERM $pidstat_pid
else
  # Print stats header
  ps -p $quarkus_pid -o %cpu,rss,vsz | head -1
  sleep 1;
  # Print stats
  for (( i=1; i<$WARMUP; i++ )); do ps -p $quarkus_pid -o %cpu,rss,vsz | tail -1;sleep 1;done;
fi

echo "----- Stopped stats, waiting load to complete"

wait $ap_pid

if [ "${PERF}" = true ]; then
  kill -SIGINT $stat_pid
fi

wait $load_generation_pid

echo "----- Profiling and workload completed: killing server"

kill -SIGTERM $quarkus_pid
