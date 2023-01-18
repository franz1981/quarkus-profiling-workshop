# hello-world-app Project

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: https://quarkus.io/ .

## Packaging and running the application

The application can be packaged using:
```shell script
./mvnw package
```
It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:
```shell script
./mvnw package -Dquarkus.package.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using: 
```shell script
./mvnw package -Pnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using: 
```shell script
./mvnw package -Pnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/hello-world-app-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult https://quarkus.io/guides/maven-tooling.

## Related Guides

- Mutiny ([guide](https://quarkus.io/guides/mutiny-primer)): Write reactive applications with the modern Reactive Programming library Mutiny
- RESTEasy Reactive ([guide](https://quarkus.io/guides/resteasy-reactive)): A JAX-RS implementation utilizing build time processing and Vert.x. This extension is not compatible with the quarkus-resteasy extension, or any of the extensions that depend on it.

## Provided Code

### RESTEasy Reactive

Easily start your Reactive RESTful Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)

# How to load generate HTTP workload

How to install the chosen load generator: https://hyperfoil.io/quickstart/quickstart1.html

Why Hyperfoil? https://www.slideshare.net/InfoQ/how-not-to-measure-latency-60111840

## Preparation Steps

Download and unzip the generator:
```bash
wget https://github.com/Hyperfoil/Hyperfoil/releases/download/hyperfoil-all-0.24/hyperfoil-0.24.zip \
    && unzip hyperfoil-0.24.zip \
    && cd hyperfoil-0.24
```

From within the hyperfoil's `/bin` folder and assuming the Quarkus hello world endpoint to be up and running:
```bash
[hyperfoil@in-vm]$ wrk -t 1 -c 10 -d 10s http://localhost:8080/hello
```
While the benchmark is completed, it will output something like:
```bash
Running 10s test @ http://localhost:8080/hello
  1 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   192.64μs  317.09μs  66.06ms   99.77%
    Req/Sec   45764.73  17108.08  58857.00     90.91
  503412 requests in 10.002s,  70.57MB read
Requests/sec: 50331.13
Transfer/sec:   7.06MB
```
Is it possible to start a CLI interactive sessionn with hyperfoil and both report in html
or perform quick diff between `wrk` runs.

## Which profiler? Async-profiler OBVIOUSLY!

Although [async-profiler](https://github.com/jvm-profiling-tools/async-profiler) is awesome, but using it can be made simpler
with [ap-loader](https://github.com/jvm-profiling-tools/ap-loader).

Download it:
```bash
wget https://github.com/jvm-profiling-tools/ap-loader/releases/download/2.9/ap-loader-all.jar
```

Let's have fun with the various scripts in the `/scripts` folder of the project!

## Cheat Codes

The benchmarking scripts allow to capture more information by using the proper output format.

e.g.

```bash
$ ./benchmark.sh -u persons/agesum -r 4000 -e cache-misses -f jfr
```
the resulting output file should be named as `<quarkus pid>_cache_misses.jfr`.
It then can be opened (if you dare!! ) with [JMC 8.x](https://www.oracle.com/java/technologies/javase/products-jmc8-downloads.html)
or can be used the built-in `jfr2flame` converter to produce flamegraphs with
more information e.g. line of code to be blamed, if available

```bash
$ java -jar ap-loader-all.jar converter jfr2flame <quarkus pid>_cache_misses.jfr --threads --lines out.html
```
More informations about converter are part of the command's help or can be found on the async profiler homepage.

## How to compare benchmarking results?
Hyperfoil allow to easily compare between two runs, but sadly, given that
we've used the CLI versions of `wrk`/`wrk2` (load generation CLI commands) we don't have an easy way to find identifier 
for such runs.

Leveraging on our knowledge of the benchmarking script, it performs 2 runs:
- a warmup run with all-out throughput
- a second run with the configured throughput (if any)

This means that for each benchmarking session it produces 2 runs on in Hyperfoil
and the ones to be compared must be taken considering the warming up ones too.

Assuming two benchmarks runs already completed:
```bash
# run the hyperfoil CLI
$ hyperfoil-0.23/bin/cli.sh
# start a local session on it
[hyperfoil]$ start-local 
Starting controller in default directory (/tmp/hyperfoil)
Controller started, listening on 127.0.0.1:33161
Connecting to the controller...
Connected to 127.0.0.1:33161!
# now on we can interact with the local env
[hyperfoil@in-vm]$ runs
   RUN_ID  BENCHMARK  STARTED                  TERMINATED               DESCRIPTION
!  0000    wrk        2023/01/17 04:53:15.985  2023/01/17 04:53:31.989             
!  0001    wrk        2023/01/17 04:53:35.261  2023/01/17 04:53:51.267             
# that could be a loooooooong list by the end of the workshop :P
#                           ...
!  0067    wrk        2023/01/18 12:37:06.368  2023/01/18 12:37:32.380             
!  0068    wrk2       2023/01/18 12:37:36.843  2023/01/18 12:38:02.852             
!  0069    wrk        2023/01/18 12:39:00.641  2023/01/18 12:39:26.650             
!  006A    wrk2       2023/01/18 12:39:31.091  2023/01/18 12:39:57.099
```
As said before, given that each benchmark script run perform 2 hyperfoil runs, the last 2
warmed up runs are `0068` and `006A`.

Let's see what `compare` says:
```bash
[hyperfoil@in-vm]$ compare 0068 006A
Comparing runs 0068 and 006A
PHASE        METRIC   REQUESTS    MEAN                 p50                p90                   p99                   p99.9                p99.99
calibration  request  +8(+0.03%)   -5.85 ms(-524.95%)      +0 ns(+0.00%)  -36.20 ms(-7214.30%)   -28.57 ms(-153.52%)  -28.57 ms(-153.52%)  -28.57 ms(-153.52%)
test         request  -8(-0.01%)   -1.45 ms(-257.71%)      +0 ns(+0.00%)    -1.01 ms(-200.41%)  -29.51 ms(-5882.05%)  -16.52 ms(-122.33%)  -16.52 ms(-122.33%)
```
Is it clear that under the same load (whatever it is), the 2 perform very differently, with `006A` getting `1 ms` `p90` lower
latencies, that's an improvement of `-200.41%` (!!!).

To manually study the dynamics of each run, is it possible to produce an html report for each with:
```bash
[hyperfoil@in-vm]$ report 0068 --destination=linkedlist.html
```
You can then open the `html` file an check the rate progress, latency distributions and errors.

