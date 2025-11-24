#!/bin/bash

URL=hello

DURATION=40

EVENT=cpu

# this can be html or jfr
FORMAT=html

JFR=false

WRK_THREADS=2

RATE=0

CONNECTIONS=10

JFR_ARGS=

TOTAL=false

# default to 1 GB heap and using Parallel GC
JVM_ARGS="-Xmx1g -Xms1g -XX:+UseParallelGC"

# number of processors to report to the JVM via -XX:ActiveProcessorCount (unset by default)
PROCESSORS=2
# track whether the user explicitly provided -p; default false
PROCESSORS_USER_SET=false

# optional CPU affinity list (e.g. "1,2" or "0-3") to pin the process using taskset on Linux
# Default to CPUs 0 and 1 so the benchmark uses two cores by default on Linux
CPU_AFFINITY="0,1"

# human-friendly description of affinity/processor constraints (set later)
AFFINITY_DESC=

# Special environment flag: when set to "true" (export PERF_STAT=true), the script will
# use `perf stat` attached to the Quarkus PID instead of async-profiler/ap-loader.
# Disabled by default.
PERF_STAT=${PERF_STAT:-false}

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
   echo "r    rate of the load generation phase, in requests/sec."
   echo "     default not specified (0)"
   echo ""
   echo "c    number of connections used by the load generator."
   echo "     default is 10"
   echo ""
   echo "p    if specified with a number, report that many processors to the JVM via -XX:ActiveProcessorCount."
   echo "     e.g. -p 2 (do NOT confuse with CPU affinity)."
   echo "     default is 2 (JVM will use 2 cores via -XX:ActiveProcessorCount)"
   echo ""
   echo "a    CPU affinity list to pin the java process to specific cores (Linux only)."
   echo "     e.g. -a 1,2 will run the JVM on cores 1 and 2 using taskset."
   echo "     Default behavior: the script pins to CPUs 0 and 1 on Linux by default (you can override with -a)."
   echo "     On macOS/other OSes taskset is not available; the script will warn and fall back to -XX:ActiveProcessorCount if provided."
   echo ""
   echo "g    if specified, run async-profiler with the --total flag."
   echo "     default is false"
   echo ""
   echo "Note: you can also enable PERF_STAT by exporting PERF_STAT=true in the environment to run 'perf stat' attached to the Quarkus PID instead of async-profiler."
}

while getopts "hu:e:f:d:jr:c:p:a:g" option; do
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
      r) RATE=${OPTARG}
         ;;
      c) CONNECTIONS=${OPTARG}
         ;;
      p) PROCESSORS=${OPTARG}
         PROCESSORS_USER_SET=true
         ;;
      a) CPU_AFFINITY=${OPTARG}
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

jbang app install wrk@hyperfoil || true

jbang app install wrk2@hyperfoil || true

echo "----- Benchmarking endpoint ${FULL_URL}"

# set sysctl kernel variables only if necessary
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  current_value=$(sysctl -n kernel.perf_event_paranoid)
  if [ "$current_value" -ne -1 ]; then
    echo "----- Setting kernel params Linux Perf usage"
    sudo sysctl kernel.perf_event_paranoid=-1
    sudo sysctl kernel.kptr_restrict=0
  fi
fi

if [ "${JFR}" = true ]; then
   JFR_ARGS=-XX:+FlightRecorder
fi

trap 'echo "cleaning up quarkus process"; kill ${quarkus_pid} 2>/dev/null || true' SIGINT SIGTERM EXIT

# if PROCESSORS is set and either the user explicitly asked for it or no CPU affinity was requested,
# constrain the java process to report that many cores via -XX:ActiveProcessorCount. If the user requested
# CPU affinity (via -a) and taskset is available, we avoid injecting ActiveProcessorCount to prevent mismatches.
if [ -n "${PROCESSORS}" ] && { [ "${PROCESSORS_USER_SET}" = "true" ] || [ -z "${CPU_AFFINITY}" ]; }; then
  JVM_ARGS=${JVM_ARGS}" -XX:ActiveProcessorCount=${PROCESSORS}"
  echo "----- Constraining Java to report ${PROCESSORS} cores via -XX:ActiveProcessorCount"
  # reflect this in the status description shown after startup if not already set by affinity pinning
  if [ -z "${AFFINITY_DESC}" ]; then
    AFFINITY_DESC="reporting ${PROCESSORS} cores"
  fi
fi

# We will construct the java invocation at runtime so any changes to JVM_ARGS (e.g. from affinity fallback)
# are included. AFFINITY_DESC is used to provide accurate status about pinning.

# helper: count CPUs from affinity string like "1,2,4-6"
count_cpus_from_list() {
  local list="$1"
  local count=0
  IFS=',' read -ra parts <<< "$list"
  for token in "${parts[@]}"; do
    if [[ "$token" == *"-"* ]]; then
      start=${token%-*}
      end=${token#*-}
      # ensure numeric
      if [[ "$start" =~ ^[0-9]+$ ]] && [[ "$end" =~ ^[0-9]+$ ]]; then
        range=$((end - start + 1))
        if [ "$range" -gt 0 ]; then
          count=$((count + range))
        fi
      fi
    else
      if [[ "$token" =~ ^[0-9]+$ ]]; then
        count=$((count + 1))
      fi
    fi
  done
  echo "$count"
}

if [ -n "${CPU_AFFINITY}" ]; then
  # Prefer taskset when available (works on Linux). If taskset is missing, fall back to ActiveProcessorCount.
  if command -v taskset >/dev/null 2>&1; then
    echo "----- Starting Quarkus pinned to CPUs ${CPU_AFFINITY} with taskset"
    taskset -c ${CPU_AFFINITY} java ${JVM_ARGS} ${JFR_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
    AFFINITY_DESC="pinned to CPUs ${CPU_AFFINITY}"
  else
    echo "----- WARNING: taskset not found; attempting to fall back to -XX:ActiveProcessorCount based on the affinity list"
    affinity_count=$(count_cpus_from_list "${CPU_AFFINITY}")
    if [ -n "${affinity_count}" ] && [ "${affinity_count}" -gt 0 ]; then
      if [ "${PROCESSORS_USER_SET}" = "false" ]; then
        PROCESSORS=${affinity_count}
        JVM_ARGS=${JVM_ARGS}" -XX:ActiveProcessorCount=${PROCESSORS}"
        echo "----- Falling back: constraining Java to report ${PROCESSORS} cores via -XX:ActiveProcessorCount"
        if [ -z "${AFFINITY_DESC}" ]; then
          AFFINITY_DESC="reporting ${PROCESSORS} cores (from affinity fallback)"
        fi
      else
        echo "----- PROCESSORS explicitly set by user (${PROCESSORS}); not overriding with affinity-derived count"
      fi
    else
      echo "----- WARNING: couldn't parse CPU affinity list '${CPU_AFFINITY}'; starting JVM without affinity or processor constraints"
    fi
    java ${JVM_ARGS} ${JFR_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
  fi
else
  java ${JVM_ARGS} ${JFR_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar ../target/quarkus-app/quarkus-run.jar &
fi

quarkus_pid=$!

sleep 2
# Verify and print CPU affinity if taskset is available (helps debug default affinity behavior)
if command -v taskset >/dev/null 2>&1; then
  echo "----- Verifying CPU affinity for pid ${quarkus_pid}"
  taskset -pc ${quarkus_pid} || true
else
  echo "----- taskset not installed; cannot verify CPU affinity via taskset"
fi

if [ -n "${AFFINITY_DESC}" ]; then
  echo "----- Quarkus running at pid $quarkus_pid ${AFFINITY_DESC}"
elif [ -n "${PROCESSORS}" ]; then
  echo "----- Quarkus running at pid $quarkus_pid reporting ${PROCESSORS} cores"
else
  echo "----- Quarkus running at pid $quarkus_pid using all available cores"
fi

if [ "${RATE}" != "0" ]
then
  echo "----- Start fixed rate test at ${RATE} requests/sec and profiling"
  jbang wrk2@hyperfoil -R ${RATE} -c ${CONNECTIONS} -t ${WRK_THREADS} -d ${DURATION}s ${FULL_URL} &
else
  echo "----- Start all-out test and profiling"
 jbang wrk@hyperfoil -c ${CONNECTIONS} -t ${WRK_THREADS} -d ${DURATION}s ${FULL_URL} &
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

# Profiler start logic: if PERF_STAT is enabled use perf stat; otherwise use JFR or async-profiler as before
if [ "${PERF_STAT}" = "true" ]; then
  echo "----- Starting perf stat attached to quarkus application ($quarkus_pid) for ${PROFILING}s"
  # perf stat will run the provided command (sleep) for the desired duration while attaching to the PID
  # output file: timestamp_perfstat.txt
  perf stat -p $quarkus_pid -o ${NOW}_perfstat.txt sleep ${PROFILING} &
else
  if [ "${JFR}" = true ]
  then
    jcmd $quarkus_pid JFR.start duration=${PROFILING}s filename=${NOW}.jfr dumponexit=true settings=profile
  else
    echo "----- Starting async-profiler on quarkus application ($quarkus_pid)"
    jbang ap-loader@jvm-profiling-tools/ap-loader profiler ${TOTAL_ARG} --total -e ${EVENT} -t -d ${PROFILING} -f ${NOW}_${EVENT}.${FORMAT} $quarkus_pid &
  fi
fi

ap_pid=$!

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
