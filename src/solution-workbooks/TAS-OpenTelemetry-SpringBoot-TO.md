# Instrumenting TAS OpenTelemetry (OTel) for Spring Boot application with Tanzu Observability (TO)/Wavefront 

The OpenTelemetry agent for Java based spring-boot application enables JMX profiling, tracing, eventing on any Java 8+ application and dynamically injects bytecode to capture telemetry from a number of popular libraries and frameworks. This provides the ability to gather telemetry data from a Java application without code changes.
The OpenTelemetry Java agent uses `OTLP` exporter configured to send data to OpenTelemetry collector

Here we will enable Spring Micrometer traces for a sample Spring boot application through the OpenTelemetry Java agent that is available with the latest [Java buildpack](https://github.com/cloudfoundry/java-buildpack.git) `v4.66.0`.

Before using the Buildpack to fetch the metrics, we need to enable OpenTelemetry Collector agent on the TAS side under Wavefront Nozzle tile settings.

![OTEL](img/TAS-OpenTelemetry-SpringBoot-TO/image1.jpg)

## Configuring OTel on Tanzu Observability by Wavefront Nozzle

In this section, we configure the OTel on Tanzu observability by configuraing few parameters in the TAS for Wavefront tile.

1. On the TAS for Wavefront tile, add the below settings in the `Config` section under **Wavefront Proxy Config** > **Custom Proxy Configuration** > **Custom**.
    ```bash
    otlpGrpcListenerPorts=4317
    otlpHttpListenerPorts=4318
    otlpResourceAttrsOnMetricsIncluded=true
    ```
1. Add a Pre-processing rule under the `Preprocessor Rules` section under **Wavefront Proxy Config** > **Custom Proxy Configuration** > **Custom**.
    ```bash
    '4317':
    - rule    : drop_process_command
        action  : dropTag
        tag     : process.command_args
    ```

    ![TAS-TO-Settings](img/TAS-OpenTelemetry-SpringBoot-TO/image2.jpg)
1.	Save the changes and Apply.

    > Note
    Refer to the following documents for the parameter references.
    - https://opentelemetry.io/docs/languages/java/automatic/
    - https://opentelemetry.io/docs/languages/java/automatic/spring-boot/


## Deploying a sample spring-boot application and creating the service for Otel-Collector

Next step is to create a spring-boot application with the java-buildpack (v4.66.0) that has the open-telemetry JAVA agent. TAS 5.0.4 has been used for this demonstration purpsoe.

The spring music application is cloned from https://github.com/cloudfoundry-samples/spring-music in the jumpbox.  

1. Clone the Spring music applicaiton from [Github](https://github.com/cloudfoundry-samples/spring-music) to jumpbox.

1. Go to the spring-music directory and run:
    ```bash
    $ cf push spring-music -f manifest.yml -b https://github.com/cloudfoundry/java-buildpack.git
    ```
1. Check the application status:
    ```bash
    $ cf app spring-music       
    Showing health and status for app spring-music in org otel-test / space otel-space as admin...
    name:              spring-music
    requested state:   started
    routes:            spring-music-agile-baboon-rr.apps.h2o-2-22348.h2o.vmware.com
    last uploaded:     Fri 02 Feb 12:23:31 IST 2024
    stack:             cflinuxfs4
    buildpacks:        
        name                                                 version                                                              detect output   buildpack name
        https://github.com/cloudfoundry/java-buildpack.git   9e8f9be-https://github.com/cloudfoundry/java-buildpack.git#9e8f9be   java            java
    type:           web
    sidecars:       
    instances:      1/1
    memory usage:   1024M
        state     since                  cpu    memory         disk           logging        details
    #0   running   2024-02-06T09:31:09Z   0.6%   422.9M of 1G   320.3M of 1G   0/s of 16K/s   
    type:           task
    sidecars:       
    instances:      0/0
    memory usage:   1024M
    There are no running instances of this process.
    ```
1. Create a User-provided service for the Spring-Music application and bind to it.
    ```bash
    $ cf cups spring-music-otel-collector -p '{"otel.exporter.otlp.endpoint":"http://wavefront-proxy.service.internal:4317","otel.exporter.otlp.metrics.temporality.preference":"delta","otel.resource.attributes":"application=spring-music,cluster=otel-test,shard=ap1","otel.traces.exporter":"otlp","otlp.metrics.exporter":"otlp","otel.exporter.otlp.protocol":"grpc","otel.service.name":"spring-music-svc","otel.jmx.target.system":"jetty,kafka-broker,tomcat","otel.javaagent.debug":"true"}'
    ```
1. Bind the service to the spring-music application and restage the app.
    ```bash
    $ cf bind-service spring-music spring-music-otel-collector  && cf restage spring-music

    $ cf service spring-music-otel-collector
    Showing info of service spring-music-otel-collector in org otel-test / space otel-space as admin...
    name:                spring-music-otel-collector
    guid:                c6e74b4b-7680-4915-b56d-87268988aafd
    type:                user-provided
    tags:                
    route service url:   
    syslog drain url:    
    Showing status of last operation:
    status:    create succeeded
    message:   Operation succeeded
    started:   2024-02-02T06:52:23Z
    updated:   2024-02-02T06:52:23Z
    Showing bound apps:
    name           binding name   status             message
    spring-music                  create succeeded   
    ```
    ![Spring-app](img/TAS-OpenTelemetry-SpringBoot-TO/image3.jpg)


## Observing the Metrics in VMware Aria for Operations (Tanzu Observability)

For Spring micrometer traces for the application, the data is populated in the Spring Boot Dashboard under Tanzu Observability portal

![Spring-boot-dashboard](img/TAS-OpenTelemetry-SpringBoot-TO/to-1.jpg)

**JVM Utilization**:

![JVM-Utilization](img/TAS-OpenTelemetry-SpringBoot-TO/to-2.jpg)

**Garbage collection and Buffer pools**

![Garbage collection and Buffer pools](img/TAS-OpenTelemetry-SpringBoot-TO/to-3.jpg)

**JDBC connections**

![JDBC connections](img/TAS-OpenTelemetry-SpringBoot-TO/to-4.jpg)



The telemetry data further enriches to provide tracing information, services call, operational tasks, latency between the classes and system calls

![Temeletry Data](img/TAS-OpenTelemetry-SpringBoot-TO/to-5.jpg)

![Temeletry Data](img/TAS-OpenTelemetry-SpringBoot-TO/to-6.jpg)

![Temeletry Data](img/TAS-OpenTelemetry-SpringBoot-TO/to-7.jpg)

![Temeletry Data](img/TAS-OpenTelemetry-SpringBoot-TO/to-8.jpg)

## Conclusion

- The current implementation helps in getting Spring boot app tracing to TO tile from TAS through the wavefront proxy as existing TAS firehose doesn’t allow existing tracing metrics from the platform
- Using Open Telemetry Javaagent in the buildpack allows the user to auto instrument most of the data required from the spring boot application without the need to configure manually. 
