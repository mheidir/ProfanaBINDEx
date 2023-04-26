# ProfanaBINDEx
A prepared Docker Compose file with initial database files mounted on host disk instead of on container image allowing data to be persistent.

## What is Docker?
Docker is an open platform for developing, shipping, and running applications. Docker enables you to separate your applications from your infrastructure so you can deliver software quickly. With Docker, you can manage your infrastructure in the same way you manage your applications. By taking advantage of Docker’s methodologies for shipping, testing, and deploying code quickly, you can significantly reduce the delay between writing code and running it in production.

## What is Prometheus and Grafana?
Prometheus is an open-source systems monitoring and alerting toolkit originally built at SoundCloud. Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.
Prometheus's main features are:
- a multi-dimensional data model with time series data identified by metric name and key/value pairs
- PromQL, a flexible query language to leverage this dimensionality
- time series collection happens via a pull model over HTTP
- pushing time series is supported via an intermediary gateway
- targets are discovered via service discovery or static configuration
- multiple modes of graphing and dashboarding support

Grafana is a multi-platform open source analytics and interactive visualization web application. It provides charts, graphs, and alerts for the web when connected to supported data sources. There is also a licensed Grafana Enterprise version with additional capabilities available as a self-hosted installation or an account on the Grafana Labs cloud service. It is expandable through a plug-in system. End users can create complex monitoring dashboards using interactive query builders. Grafana is divided into a front end and back end, written in TypeScript and Go, respectively.
As a visualization tool, Grafana is a popular component in monitoring stacks, often used in combination with time series databases such as InfluxDB, Prometheus and Graphite; monitoring platforms such as Sensu, Icinga, Checkmk, Zabbix, Netdata, and PRTG; SIEMs such as Elasticsearch and Splunk; and other data sources. The Grafana user interface was originally based on version 3 of Kibana.
Prometheus is an open source monitoring system for which Grafana provides out-of-the-box support.

## What is BIND Exporter?
In order to process the BIND Statistics published via the statistics channel to make it compatible to Prometheus data scraping method, bind_exporter\([https://github.com/prometheus-community/bind_exporter](https://github.com/prometheus-community/bind_exporter)\) performs the conversion. This allows the data to later be absorbed by Grafana for generating reports and graphs.

### Advantages and Purpose
- Simplify setup and deployment for quick testing turnaround
- Extracts BIND statistics and allows information to be consumed by Prometheus before graphically visualizing it on Grafana
- Services are internally integrated with minimum configuration
- Data is persistent
- Recommended for POC and Demo. Not for Production Use
- Reduces complexity


## Description
This document shows the steps to get the Docker images ready for deployment and integration quickly before data is collected and presented.
Clone the basic package prepared which contains the data for both Prometheus and Grafana mounted onto local persistent storage instead of within the docker image which will be destroyed when the image gets re-built or destroyed.

The process of deploying the images are as follows:
1.	Install Docker (this process is documented on Docker website for each OS, including Windows)
2.	Download and Extract Docket Compose (WSL is used in this example)
3.	Build and Run Docker Compose
4.	Enable BIND Statistics
5.	Configure BIND Exporter
6.	Configure Prometheus
7.	Configure Grafana


## Install Docker
Refer to the following links based on the system that is used:
- Windows
-- https://docs.docker.com/desktop/install/windows-install/
- Debian
-- https://docs.docker.com/engine/install/debian/
- Ubuntu
-- https://docs.docker.com/engine/install/ubuntu/
- RHEL
-- https://docs.docker.com/engine/install/rhel/

## Build and Run Docker Compose
There are 2 ways to build and start the images, using the start.sh script or manually typing them.
### First Method:
1. Run the command to make it executable :
`# chmod +x start.sh`

2. To immediately create and start the images:
`# ./start.sh`

3. Verify the docker images are running:
`# docker ps -a`

### Second Method:
Via Command line:
- To build the docker containers:
`# docker compose -f docker-compose.yml create`

- To start the docker containers
`# docker compose -f docker-compose.yml start`

- To stop the containers
`# docker compose -f docker-compose.yml down`



## Enable BIND Statistics
In order for BIND Exporter to retrieve the data from SOLIDserver, BIND Statistics Channel must be configured and exposed via a unique port number on TCP. This configuration have to be performed via command line.
1. SSH or access the CLI via terminal console
2. Select Tools > Shell
3. Change to root user mode:
`# sudo su`

4. Edit the eip_global.conf file and add the following statement:
`# vi /data1/etc/namedb/eip_global.conf`

`# inet 10.10.10.1 port 8053`
Replace IP address as necessary

5. Save the file and quit
`# :wq`

6. Next, edit the options_include.conf and add the statement:
`# zone-statistics yes;`

7.	Save the file and quit
`# :wq`

8. With a web browser, browse the following URLs to view the exposed statistics:
- XML format: http://10.10.10.1:8053
- JSON format: http://10.10.10.1:8053/json
Note: BIND Exporter retrieves the data in XML format

## Configure BIND Exporter
BIND Exporter docker image should be running. But no configuration has been set. By default it is listening on port 9119 however it is not configured to retrieve data from BIND servers yet. This step is to execute a command that runs in the background to expose the data in a format that is acceptable for Prometheus. Each BIND server statistics is exposed via unique ports.
1. Access Docker image shell by executing the command:
`# docker exec -it -u root srv_bindexporter /bin/sh`


2. In the shell, set up the BIND server to retrieve the statistics from, expose it on to a port and run the service in the background:
`# bind_exporter --bind.stats-url=http://10.10.10.1:8053 --web.listen-address=:9121 --bind.stats-groups=server,view,tasks &`

bind_exporter = service to retrieve and expose the data
--bind.stats-url=http://10.10.10.1:8053 = URL on BIND server where the statistics are exposed for retrieval
--web.listen-address=:9121 = the port where Prometheus will retrieve the metrics from the BIND Exporter 
--bind.stats-groups=server,view,tasks  = metrics data to be exposed to Prometheus
& = execute command and let it run in the background

3. Exit the container shell:
`# exit`


4. To verify whether metrics is published correctly, access via the following command on your system:
- Lookup IP address of srv_bindexporter
`# docker inspect srv_bindexporter | grep IPAddress`
 

- Get the metrics from the IP address specifying the port
`# curl http://172.21.0.2:9121/metrics`
 Note: There should be lines that starts with “bind_*xxx”


## Configure Prometheus
In order for Prometheus to scrape the prepared data from BIND Exporter, the target to the BIND Exporter needs to be defined. Edit the Prometheus configuration file with the target information.
1. Within the directory: /dev-pgrafana, edit the configuration file to add the additional target that was created on BIND Exporter
`# cd prometheus/etc`

2. Edit the file Prometheus.yml and add the following statement:
`# vi prometheus.yml`

- job_name: "sds-ns1"
  static_configs:
    - targets: ['srv_bindexporter:9121']
      labels:
          alias: "sds-ns1”

3. Restart Prometheus:
`# docker restart srv_prometheus`


4. Verify Prometheus is accessible and the new targets are showing with state: up
- Access: http://localhost:9090
- Status > Targets

## Configure Grafana
Next is to configure Grafana to read the metrics from the designated Prometheus, import the dashboard prepared as JSON file into Grafana and display the default metrics.
1. Access Grafana and login using default account
- http://localhost:3000
Username: admin
Password: admin
- Skip the next prompt if not replacing password with a new one

2. Click on Configuration > Data Sources
 

3. Click on “Add new data source”
4. Select Prometheus from the list
 

5. Enter the following information:
- Name: SOLIDservers
- URL: http://srv_prometheus:9090
Leave the rest as default

6.	Click Save & Test

7.	Import the included JSON file to create dashboard in Grafana using it as a template
- Click on Dashboards > Import
 
8.	Drag and drop the JSON file named: bind9-exporter-dns_rev4.json
- Click Load

9.	The newly added dashboard should appear and data will be populated automatically. Wait for a few minutes for it to be properly loaded.

