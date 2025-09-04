# Backend Service - ECS Cluster Indépendant

Ce module Terraform crée un cluster ECS indépendant pour le service backend Quarkus avec accès à la base de données RDS.

## Fonctionnalités

- **Cluster ECS indépendant** : Cluster dédié au service backend
- **Accès à la base de données** : Connexion sécurisée à la base RDS via Secrets Manager
- **Intégration Keycloak** : Configuration OIDC avec Keycloak
- **Auto-scaling** : Mise à l'échelle automatique basée sur l'utilisation CPU
- **Logging** : Logs centralisés dans CloudWatch
- **Sécurité** : Rôles IAM dédiés et accès aux secrets

## Prérequis

1. **Base de données RDS** : Le module `aws/02-databases` doit être déployé
2. **Réseau** : VPC avec sous-réseaux privés et groupes de sécurité
3. **Load Balancer** : ALB avec target group pour le backend
4. **ECR** : Repository ECR pour l'image backend
5. **Keycloak** : Service Keycloak déployé (pour les credentials)

## Variables requises

```hcl
# Variables obligatoires
backend_repository_url           = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/navigator-backend"
db_credentials_secret_arn        = "arn:aws:secretsmanager:eu-west-3:123456789012:secret:navigator-db-credentials-xxxxx"
keycloak_credentials_secret_arn  = "arn:aws:secretsmanager:eu-west-3:123456789012:secret:navigator-keycloak-credentials-xxxxx"
ecs_security_group_id           = "sg-xxxxxxxxx"
private_subnet_ids              = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
backend_target_group_arn        = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:targetgroup/navigator-backend/xxxxxxxxx"
alb_listener_arn                = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:listener/app/navigator-alb/xxxxxxxxx/xxxxxxxxx"
```

## Configuration de la base de données

Le backend accède à la base de données RDS via les secrets stockés dans AWS Secrets Manager :

### Secrets utilisés :
- `QUARKUS_DATASOURCE_JDBC_URL` : URL de connexion JDBC
- `QUARKUS_DATASOURCE_USERNAME` : Nom d'utilisateur de la base
- `QUARKUS_DATASOURCE_PASSWORD` : Mot de passe de la base

### Configuration Keycloak :
- `QUARKUS_OIDC_AUTH_SERVER_URL` : URL du serveur Keycloak
- `QUARKUS_OIDC_CLIENT_ID` : ID client OIDC
- `QUARKUS_OIDC_CREDENTIALS_SECRET` : Secret client OIDC

## Utilisation

1. **Déployer la base de données** :
   ```bash
   cd aws/02-databases
   terraform init
   terraform apply
   ```

2. **Déployer Keycloak** (pour obtenir les credentials) :
   ```bash
   cd aws/keycloak
   terraform init
   terraform apply
   ```

3. **Déployer le backend** :
   ```bash
   cd aws/back
   terraform init
   terraform apply
   ```

## Variables optionnelles

```hcl
# Configuration ECS
ecs_config = {
  cpu           = 256
  memory        = 512
  desired_count = 1
}

# Tags communs
common_tags = {
  Project     = "navigator"
  Environment = "dev"
  ManagedBy   = "terraform"
}
```

## Outputs

- `backend_cluster_id` : ID du cluster ECS backend
- `backend_cluster_name` : Nom du cluster ECS backend
- `backend_service_id` : ID du service ECS backend
- `backend_task_definition_arn` : ARN de la définition de tâche
- `backend_log_group_name` : Nom du groupe de logs CloudWatch

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ALB           │    │   ECS Cluster   │    │   RDS Database  │
│   (Load Balancer)│───▶│   Backend       │───▶│   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Keycloak      │
                       │   (Auth Server) │
                       └─────────────────┘
```

## Sécurité

- **Rôles IAM dédiés** : Rôles séparés pour l'exécution et les tâches
- **Accès aux secrets** : Permissions limitées aux secrets nécessaires
- **Réseau privé** : Déploiement dans des sous-réseaux privés
- **Chiffrement** : Communication chiffrée avec la base de données

## Monitoring

- **CloudWatch Logs** : Logs centralisés avec rétention de 7 jours
- **Health Checks** : Vérifications de santé sur `/q/health`
- **Auto-scaling** : Mise à l'échelle basée sur l'utilisation CPU (70%)

## Dépannage

1. **Problème de connexion DB** : Vérifier les permissions IAM et les secrets
2. **Service ne démarre pas** : Vérifier les logs CloudWatch
3. **Health check échoue** : Vérifier que l'application répond sur le port 8080
4. **Problème Keycloak** : Vérifier que Keycloak est déployé et accessible