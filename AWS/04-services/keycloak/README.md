# Keycloak Service - ECS Cluster Indépendant

Ce module Terraform crée un cluster ECS indépendant pour le service Keycloak avec accès à la base de données RDS.

## Fonctionnalités

- **Cluster ECS indépendant** : Cluster dédié au service Keycloak
- **Accès à la base de données** : Connexion sécurisée à la base RDS PostgreSQL
- **Gestion des secrets** : Credentials Keycloak stockés dans Secrets Manager
- **Auto-scaling** : Mise à l'échelle automatique basée sur l'utilisation CPU
- **Logging** : Logs centralisés dans CloudWatch
- **Sécurité** : Rôles IAM dédiés et accès aux secrets

## Prérequis

1. **Base de données RDS** : Le module `aws/02-databases` doit être déployé
2. **Réseau** : VPC avec sous-réseaux privés et groupes de sécurité
3. **Load Balancer** : ALB avec target group pour Keycloak
4. **ECR** : Repository ECR pour l'image Keycloak

## Variables requises

```hcl
# Variables obligatoires
keycloak_repository_url = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/navigator-keycloak"
db_credentials_secret_arn = "arn:aws:secretsmanager:eu-west-3:123456789012:secret:navigator-db-credentials-xxxxx"
ecs_security_group_id = "sg-xxxxxxxxx"
private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
keycloak_target_group_arn = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:targetgroup/navigator-keycloak/xxxxxxxxx"
alb_listener_arn = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:listener/app/navigator-alb/xxxxxxxxx/xxxxxxxxx"
```

## Configuration de la base de données

Keycloak accède à la base de données RDS via les secrets stockés dans AWS Secrets Manager :

### Secrets utilisés :
- `KC_DB_URL` : URL de connexion JDBC PostgreSQL
- `KC_DB_USERNAME` : Nom d'utilisateur de la base
- `KC_DB_PASSWORD` : Mot de passe de la base

### Configuration Keycloak :
- `KC_DB` : Type de base de données (postgres)
- `KC_HOSTNAME_STRICT` : Désactivé pour le développement
- `KC_HTTP_ENABLED` : HTTP activé (HTTPS géré par ALB)
- `KC_PROXY` : Mode proxy edge

## Credentials Keycloak

Les credentials Keycloak sont générés automatiquement et stockés dans Secrets Manager :

### Secrets générés :
```json
{
  "admin_user": "admin",
  "admin_password": "<mot-de-passe-généré>",
  "realm_name": "navigator",
  "auth_server_url": "http://keycloak.navigator.local:8080",
  "client_id": "navigator",
  "client_secret": "navigator-secret"
}
```

## Utilisation

1. **Déployer la base de données** :
   ```bash
   cd aws/02-databases
   terraform init
   terraform apply
   ```

2. **Déployer Keycloak** :
   ```bash
   cd aws/keycloak
   terraform init
   terraform apply
   ```

3. **Récupérer les credentials** :
   ```bash
   terraform output keycloak_credentials_secret_arn
   ```

## Variables optionnelles

```hcl
# Configuration ECS
ecs_config = {
  cpu           = 512
  memory        = 1024
  desired_count = 1
}

# Configuration Keycloak
keycloak_config = {
  admin_user = "admin"
  realm_name = "navigator"
}

# Tags communs
common_tags = {
  Project     = "navigator"
  Environment = "dev"
  ManagedBy   = "terraform"
}
```

## Outputs

- `keycloak_cluster_id` : ID du cluster ECS Keycloak
- `keycloak_cluster_name` : Nom du cluster ECS Keycloak
- `keycloak_service_id` : ID du service ECS Keycloak
- `keycloak_task_definition_arn` : ARN de la définition de tâche
- `keycloak_log_group_name` : Nom du groupe de logs CloudWatch
- `keycloak_credentials_secret_arn` : ARN du secret des credentials Keycloak

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ALB           │    │   ECS Cluster   │    │   RDS Database  │
│   (Load Balancer)│───▶│   Keycloak      │───▶│   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │ Secrets Manager │
                       │ (Credentials)   │
                       └─────────────────┘
```

## Sécurité

- **Rôles IAM dédiés** : Rôles séparés pour l'exécution et les tâches
- **Accès aux secrets** : Permissions limitées aux secrets nécessaires
- **Réseau privé** : Déploiement dans des sous-réseaux privés
- **Chiffrement** : Communication chiffrée avec la base de données
- **Mot de passe admin** : Généré automatiquement et stocké de manière sécurisée

## Monitoring

- **CloudWatch Logs** : Logs centralisés avec rétention de 7 jours
- **Health Checks** : Vérifications de santé sur `/health/ready`
- **Auto-scaling** : Mise à l'échelle basée sur l'utilisation CPU (70%)

## Configuration initiale

Après le déploiement, vous devez configurer Keycloak :

1. **Accéder à l'interface admin** :
   - URL : `https://auth.navigator.local` (via ALB)
   - Utilisateur : `admin`
   - Mot de passe : Récupéré depuis Secrets Manager

2. **Créer le realm** :
   - Créer le realm "navigator"
   - Configurer les clients OIDC
   - Configurer les utilisateurs

3. **Récupérer les credentials** :
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id <keycloak_credentials_secret_arn> \
     --query SecretString --output text | jq .
   ```

## Dépannage

1. **Problème de connexion DB** : Vérifier les permissions IAM et les secrets
2. **Service ne démarre pas** : Vérifier les logs CloudWatch
3. **Health check échoue** : Vérifier que Keycloak répond sur le port 8080
4. **Problème de configuration** : Vérifier les variables d'environnement
5. **Accès admin** : Vérifier le mot de passe dans Secrets Manager

## Notes importantes

- Keycloak nécessite plus de ressources (512 CPU, 1024 MB RAM)
- Le démarrage peut prendre plusieurs minutes (startPeriod: 120s)
- La base de données doit être accessible depuis les sous-réseaux privés
- Les credentials sont générés automatiquement et doivent être récupérés depuis Secrets Manager