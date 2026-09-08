# Jenkins CI/CD Docker Template

Docker Compose template for starting a local CI/CD environment with:

- Jenkins based on a custom local Docker image
- SonarQube Community
- PostgreSQL for SonarQube
- Nexus Repository Manager

## Architecture

| Service | Image | Local access |
| --- | --- | --- |
| Jenkins | `myjenkins-blueocean:2.580-jdk21` | [http://localhost:8081](http://localhost:8081) |
| SonarQube | `sonarqube:community` | [http://localhost:9000](http://localhost:9000) |
| Nexus | `sonatype/nexus3:3.96.0-alpine` | [http://localhost:8082](http://localhost:8082) |
| PostgreSQL | `postgres:17` | Docker network only |

The external ports are intentionally different from port `8080`, which is used by Java/Tomcat applications:

- Tomcat: `8080`
- Jenkins: `8081`
- Nexus: `8082`
- SonarQube: `9000`

## Prerequisites

- Docker Desktop is running
- Docker Compose v2
- The local Jenkins image is available:

> **Resource requirement:** Docker Desktop must allocate at least `2 CPU` to the Docker engine to run this project with Nexus. `4 CPU` is recommended when Jenkins, SonarQube, PostgreSQL, and Nexus run at the same time. With only `1 CPU`, Nexus reports a warning and the complete stack may start slowly or become unresponsive.

```powershell
docker image ls myjenkins-blueocean:2.580-jdk21
```

If the image does not exist yet, build it from your Jenkins Dockerfile or import it before starting the stack.

## Getting Started

Validate the configuration:

```powershell
docker compose config
```

Start the services:

```powershell
docker compose up -d --no-build
```

The default startup runs Jenkins only. Start SonarQube and its local PostgreSQL database when needed:

```powershell
docker compose --profile analysis up -d --no-build
```

Start Nexus separately when the pipeline needs an artifact repository:

```powershell
docker compose --profile artifacts up -d --no-build
```

CPU limits are configured to prevent saturation: Jenkins `1 CPU`, SonarQube `1.5 CPU`, PostgreSQL `0.5 CPU`, and Nexus `2 CPU`. For the lowest load, start only the profile you need instead of both profiles together.

> **Nexus requirement:** Nexus recommends a minimum of `2 CPU`. Docker Desktop must allocate at least `2 CPU` to its engine. If the host allocates only `1 CPU`, Nexus displays a resource warning and may start slowly. The `cpus: 2.0` limit is a maximum, not a permanent CPU reservation.

SonarQube connects to the local PostgreSQL service at `db:5432`. The database volume is persistent, so later starts do not repeat the initial schema setup.

Check their status:

```powershell
docker compose ps
```

View the logs:

```powershell
docker compose logs -f jenkins
docker compose logs -f sonarqube
docker compose logs -f nexus
```

Stop the containers without deleting data:

```powershell
docker compose down
```

## Persistent Volumes

Data is stored in the following Docker volumes:

- `jenkins_home`
- `sonarqube_data`
- `sonarqube_extensions`
- `sonarqube_logs`
- `sonarqube_temp`
- `nexus_data`
- `postgresql`

To delete the data as well, use the following command with caution:

```powershell
docker compose down -v
```

## Network Configuration

The IPv4 network is used by default:

```powershell
$env:NETWORK_TYPE="ipv4"
docker compose up -d
```

To enable the dual-stack network defined in the Compose file:

```powershell
$env:NETWORK_TYPE="dual"
docker compose up -d
```

From a Jenkins container, services can be reached by their Docker service names:

```text
SonarQube:  http://sonarqube:9000
Nexus:      http://nexus:8081
```

Jenkins accesses Docker through the internal `docker-proxy` `socat` service at `tcp://docker-proxy:2375`. The Docker socket is not published on a Windows host port; this keeps the Docker API reachable only inside the Compose network.

SonarQube connects to PostgreSQL through the Docker service name `db`. The default local credentials are `sonar` / `sonar`; change them before using this setup outside local development.

From Windows, use the published ports:

```text
SonarQube: http://localhost:9000
Nexus:     http://localhost:8082
Jenkins:   http://localhost:8081
```

## Initial Configuration

### Jenkins

Retrieve the initial password:

```powershell
docker exec my_custom_jenkins_docker_image-jenkins-1 `
  cat /var/jenkins_home/secrets/initialAdminPassword
```

The exact container name can be checked with:

```powershell
docker compose ps
```

### SonarQube

Default credentials are usually:

```text
Username: admin
Password: admin
```

Change the password during the first login.

### Nexus

The initial administrator password is stored in the container:

```powershell
docker exec my_custom_jenkins_docker_image-nexus-1 `
  cat /nexus-data/admin.password
```

## Troubleshooting

### Port 8081 is already in use

Identify the container using the port:

```powershell
docker ps -a --format "table {{.Names}}\t{{.Ports}}"
```

If an old Jenkins container reserves `8081`, remove it after verifying that it is no longer needed:

```powershell
docker rm <old-jenkins-container>
docker compose up -d --no-build
```

### `tls: bad record MAC` error during an image pull

This error usually indicates an interrupted connection to Docker Hub or a proxy/VPN issue. Restart Docker Desktop, then pull the images separately:

```powershell
docker desktop restart
docker pull postgres:17
docker pull sonarqube:community
docker pull sonatype/nexus3:3.96.0-alpine
docker compose up -d --no-build
```

### Check available images

```powershell
docker image ls
```

## Using This Repository as a Template

For a new project:

1. Copy `docker-compose.yml` and this `README.md`.
2. Verify the local Jenkins image and tag.
3. Change the ports if `8081`, `8082`, or `9000` are already in use.
4. Update credentials and secrets before sharing the environment.
5. Add the project `Jenkinsfile` to the application repository.

Do not use the passwords from this example in production. For a shared environment, use Docker secrets, a secrets manager, or protected Jenkins variables.

Reference Tuto
https://youtu.be/6YZvp2GwT0A?si=8JgTIb4Z5JsGNUY1