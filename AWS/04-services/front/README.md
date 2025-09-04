# Frontend Service - ECS Cluster Indépendant

Ce module Terraform crée un cluster ECS indépendant pour le service frontend React.

## Fonctionnalités

- **Cluster ECS indépendant** : Cluster dédié au service frontend
- **Application React** : Service frontend avec configuration d'environnement
- **Auto-scaling** : Mise à l'échelle automatique basée sur l'utilisation CPU
- **Logging** : Logs centralisés dans CloudWatch
- **Sécurité** : Rôles IAM dédiés

## Prérequis

1. **Réseau** : VPC avec sous-réseaux privés et groupes de sécurité
2. **Load Balancer** : ALB avec target group pour le frontend
3. **ECR** : Repository ECR pour l'image frontend
4. **Backend déployé** : Service backend accessible (pour l'API)
5. **Keycloak déployé** : Service Keycloak accessible (pour l'authentification)

## Variables requises

```hcl
# Variables obligatoires
frontend_repository_url = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/navigator-frontend"
ecs_security_group_id  = "sg-xxxxxxxxx"
private_subnet_ids     = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
frontend_target_group_arn = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:targetgroup/navigator-frontend/xxxxxxxxx"
alb_listener_arn       = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:listener/app/navigator-alb/xxxxxxxxx/xxxxxxxxx"

# Configuration React
react_config = {
  api_url        = "https://api.navigator.local"
  auth_url       = "https://auth.navigator.local"
  auth_realm     = "navigator"
  auth_client_id = "navigator"
}
```

## Configuration de l'application React

Le frontend est configuré via des variables d'environnement :

### Variables d'environnement :
- `NODE_ENV` : Environnement (production)
- `REACT_APP_API_URL` : URL de l'API backend
- `REACT_APP_AUTH_URL` : URL du serveur Keycloak
- `REACT_APP_AUTH_REALM` : Nom du realm Keycloak
- `REACT_APP_AUTH_CLIENT_ID` : ID client pour l'authentification

## Utilisation

1. **Déployer le backend** :
   ```bash
   cd aws/back
   terraform init
   terraform apply
   ```

2. **Déployer Keycloak** :
   ```bash
   cd aws/keycloak
   terraform init
   terraform apply
   ```

3. **Déployer le frontend** :
   ```bash
   cd aws/front
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

- `frontend_cluster_id` : ID du cluster ECS frontend
- `frontend_cluster_name` : Nom du cluster ECS frontend
- `frontend_service_id` : ID du service ECS frontend
- `frontend_task_definition_arn` : ARN de la définition de tâche
- `frontend_log_group_name` : Nom du groupe de logs CloudWatch

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ALB           │    │   ECS Cluster   │    │   Backend API   │
│   (Load Balancer)│───▶│   Frontend      │───▶│   (Quarkus)     │
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
- **Réseau privé** : Déploiement dans des sous-réseaux privés
- **Pas d'accès direct** : Le frontend n'a pas d'accès direct aux ressources sensibles

## Monitoring

- **CloudWatch Logs** : Logs centralisés avec rétention de 7 jours
- **Health Checks** : Vérifications de santé sur le port 80
- **Auto-scaling** : Mise à l'échelle basée sur l'utilisation CPU (70%)

## Configuration des URLs

### URLs de production :
```hcl
react_config = {
  api_url        = "https://api.navigator.com"
  auth_url       = "https://auth.navigator.com"
  auth_realm     = "navigator"
  auth_client_id = "navigator"
}
```

### URLs de développement :
```hcl
react_config = {
  api_url        = "http://localhost:8080"
  auth_url       = "http://localhost:8080"
  auth_realm     = "navigator"
  auth_client_id = "navigator"
}
```

## Dépannage

1. **Application ne se charge pas** : Vérifier les variables d'environnement React
2. **Erreurs d'authentification** : Vérifier la configuration Keycloak
3. **Erreurs API** : Vérifier que le backend est accessible
4. **Service ne démarre pas** : Vérifier les logs CloudWatch
5. **Health check échoue** : Vérifier que l'application répond sur le port 80

## Notes importantes

- Le frontend est une application statique servie par un serveur web (nginx)
- Les variables d'environnement React doivent commencer par `REACT_APP_`
- L'application est buildée au moment de la création de l'image Docker
- Les URLs doivent être accessibles depuis le navigateur des utilisateurs