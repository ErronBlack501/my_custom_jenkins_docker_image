# Jenkins CI/CD Docker Template

Template Docker Compose pour démarrer un environnement CI/CD local avec :

- Jenkins basé sur une image Docker locale personnalisée
- SonarQube Community
- PostgreSQL pour SonarQube
- Nexus Repository Manager

## Architecture

| Service | Image | Accès local |
|---|---|---|
| Jenkins | `myjenkins-blueocean:2.580-jdk21` | http://localhost:8081 |
| SonarQube | `sonarqube:community` | http://localhost:9000 |
| Nexus | `sonatype/nexus3:3.96.0-alpine` | http://localhost:8082 |
| PostgreSQL | `postgres:17` | Réseau Docker uniquement |

Les ports externes sont volontairement différents du port `8080`, utilisé par les applications Java/Tomcat :

- Tomcat : `8080`
- Jenkins : `8081`
- Nexus : `8082`
- SonarQube : `9000`

## Prérequis

- Docker Desktop démarré
- Docker Compose v2
- L'image Jenkins locale disponible :

```powershell
docker image ls myjenkins-blueocean:2.580-jdk21
```

Si l'image n'existe pas encore, construisez-la depuis votre Dockerfile Jenkins ou importez-la avant de démarrer la stack.

## Démarrage

Valider la configuration :

```powershell
docker compose config
```

Démarrer les services :

```powershell
docker compose up -d --no-build
```

Vérifier leur état :

```powershell
docker compose ps
```

Afficher les logs :

```powershell
docker compose logs -f jenkins
docker compose logs -f sonarqube
docker compose logs -f nexus
docker compose logs -f db
```

Arrêter les conteneurs sans supprimer les données :

```powershell
docker compose down
```

## Volumes persistants

Les données sont conservées dans les volumes Docker suivants :

- `jenkins_home`
- `sonarqube_data`
- `sonarqube_extensions`
- `sonarqube_logs`
- `sonarqube_temp`
- `postgresql`

Pour supprimer également les données, utilisez cette commande avec prudence :

```powershell
docker compose down -v
```

## Configuration réseau

Le réseau IPv4 est utilisé par défaut :

```powershell
$env:NETWORK_TYPE="ipv4"
docker compose up -d
```

Pour activer le réseau dual-stack défini dans le Compose :

```powershell
$env:NETWORK_TYPE="dual"
docker compose up -d
```

Depuis un conteneur Jenkins, les services sont joignables avec leurs noms Docker :

```text
SonarQube : http://sonarqube:9000
Nexus     : http://nexus:8081
PostgreSQL: db:5432
```

Depuis Windows, utilisez les ports publiés :

```text
SonarQube : http://localhost:9000
Nexus     : http://localhost:8082
Jenkins   : http://localhost:8081
```

## Première configuration

### Jenkins

Récupérer le mot de passe initial :

```powershell
docker exec my_custom_jenkins_docker_image-jenkins-1 `
  cat /var/jenkins_home/secrets/initialAdminPassword
```

Le nom exact du conteneur peut être vérifié avec :

```powershell
docker compose ps
```

### SonarQube

Identifiants initiaux habituels :

```text
Utilisateur : admin
Mot de passe : admin
```

Changez le mot de passe lors de la première connexion.

### Nexus

Le mot de passe administrateur initial est stocké dans le conteneur :

```powershell
docker exec my_custom_jenkins_docker_image-nexus-1 `
  cat /nexus-data/admin.password
```

## Dépannage

### Le port 8081 est déjà utilisé

Identifier le conteneur qui utilise le port :

```powershell
docker ps -a --format "table {{.Names}}\t{{.Ports}}"
```

Si un ancien conteneur Jenkins réserve `8081`, le supprimer après vérification :

```powershell
docker rm <ancien-conteneur-jenkins>
docker compose up -d --no-build
```

### Erreur `tls: bad record MAC` pendant un pull

Cette erreur indique généralement une interruption de connexion vers Docker Hub ou un problème de proxy/VPN. Relancer Docker Desktop, puis télécharger les images séparément :

```powershell
docker desktop restart
docker pull postgres:17
docker pull sonarqube:community
docker pull sonatype/nexus3:3.96.0-alpine
docker compose up -d --no-build
```

### Vérifier les images disponibles

```powershell
docker image ls
```

## Utilisation comme template

Pour un nouveau projet :

1. Copier `docker-compose.yml` et ce `README.md`.
2. Vérifier l'image Jenkins locale et son tag.
3. Adapter les ports si `8081`, `8082` ou `9000` sont déjà utilisés.
4. Adapter les credentials et secrets avant un usage partagé.
5. Ajouter le `Jenkinsfile` du projet dans le dépôt applicatif.

Ne pas utiliser les mots de passe présents dans cet exemple en production. Pour un environnement partagé, utiliser des secrets Docker, un gestionnaire de secrets ou des variables protégées dans Jenkins.
