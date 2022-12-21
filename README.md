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
wget https://github.com/Hyperfoil/Hyperfoil/releases/download/release-0.24/hyperfoil-0.24.zip \
    && unzip hyperfoil-0.24.zip \
    && cd hyperfoil-0.24
```

From within the hyperfoil's `/bin` folder and ssuming the Quarkus hello world endpoint to be up and running:
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