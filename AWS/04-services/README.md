# Services ECS - Architecture Indépendante

Ce dossier contient les modules Terraform pour déployer les services de l'application Navigator avec des clusters ECS indépendants.

## 📁 Structure

```
aws/04-services/
├── back/          # Service Backend (Quarkus)
├── front/         # Service Frontend (React)
├── keycloak/      # Service Keycloak (Authentification)
└── README.md      # Ce fichier
```

## 🏗️ Architecture

Chaque service a son propre cluster ECS indépendant :

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backend       │    │   Frontend      │    │   Keycloak      │
│   ECS Cluster   │    │   ECS Cluster   │    │   ECS Cluster   │
│   (Quarkus)     │    │   (React)       │    │   (Auth)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   RDS Database  │    │   Backend API   │    │   RDS Database  │
│   (PostgreSQL)  │    │   (via ALB)     │    │   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Déploiement

### Ordre de déploiement recommandé :

1. **Base de données** (prérequis) :
   ```bash
   cd aws/02-databases
   terraform init && terraform apply
   ```

2. **Keycloak** (authentification) :
   ```bash
   cd aws/04-services/keycloak
   terraform init && terraform apply
   ```

3. **Backend** (API) :
   ```bash
   cd aws/04-services/back
   terraform init && terraform apply
   ```

4. **Frontend** (interface utilisateur) :
   ```bash
   cd aws/04-services/front
   terraform init && terraform apply
   ```

## 🔗 Dépendances

### Backend (`back/`)
- **Base de données RDS** : Accès via Secrets Manager
- **Keycloak** : Credentials pour l'authentification OIDC
- **Réseau** : VPC, sous-réseaux privés, groupes de sécurité
- **Load Balancer** : ALB avec target group backend

### Frontend (`front/`)
- **Backend** : URL de l'API pour les appels
- **Keycloak** : URL et configuration pour l'authentification
- **Réseau** : VPC, sous-réseaux privés, groupes de sécurité
- **Load Balancer** : ALB avec target group frontend

### Keycloak (`keycloak/`)
- **Base de données RDS** : Accès via Secrets Manager
- **Réseau** : VPC, sous-réseaux privés, groupes de sécurité
- **Load Balancer** : ALB avec target group keycloak

## 🔐 Sécurité

- **Clusters indépendants** : Isolation des services
- **Rôles IAM dédiés** : Permissions limitées par service
- **Secrets Manager** : Credentials stockés de manière sécurisée
- **Réseau privé** : Déploiement dans des sous-réseaux privés
- **Chiffrement** : Communication chiffrée avec les bases de données

## 📊 Monitoring

- **CloudWatch Logs** : Logs centralisés par service
- **Auto-scaling** : Mise à l'échelle automatique basée sur l'utilisation CPU
- **Health Checks** : Vérifications de santé pour chaque service
- **Container Insights** : Monitoring détaillé des conteneurs

## 🛠️ Configuration

### Variables communes requises :
- `name_prefix` : Préfixe pour les noms de ressources
- `aws_region` : Région AWS
- `common_tags` : Tags communs pour toutes les ressources
- `ecs_security_group_id` : Groupe de sécurité ECS
- `private_subnet_ids` : IDs des sous-réseaux privés
- `alb_listener_arn` : ARN du listener ALB

### Variables spécifiques :
- **Backend** : `backend_repository_url`, `db_credentials_secret_arn`, `keycloak_credentials_secret_arn`
- **Frontend** : `frontend_repository_url`, `react_config`
- **Keycloak** : `keycloak_repository_url`, `db_credentials_secret_arn`, `keycloak_config`

## 📋 Avantages de cette architecture

1. **Indépendance** : Chaque service peut être déployé/mis à jour indépendamment
2. **Scalabilité** : Auto-scaling indépendant pour chaque service
3. **Sécurité** : Isolation des services et permissions limitées
4. **Maintenance** : Déploiement et rollback indépendants
5. **Monitoring** : Logs et métriques séparés par service
6. **Résilience** : Panne d'un service n'affecte pas les autres

## 🔧 Dépannage

### Problèmes courants :

1. **Dépendances manquantes** : Vérifier que les prérequis sont déployés
2. **Secrets non accessibles** : Vérifier les permissions IAM
3. **Réseau** : Vérifier les groupes de sécurité et sous-réseaux
4. **Images ECR** : Vérifier que les images sont disponibles
5. **Load Balancer** : Vérifier la configuration des target groups

### Commandes utiles :

```bash
# Vérifier les logs d'un service
aws logs tail /ecs/navigator-backend --follow

# Vérifier le statut d'un cluster
aws ecs describe-clusters --clusters navigator-backend-cluster

# Vérifier les secrets
aws secretsmanager get-secret-value --secret-id navigator-db-credentials
```

## 📚 Documentation détaillée

Chaque service a sa propre documentation :
- [Backend Service](back/README.md)
- [Frontend Service](front/README.md)
- [Keycloak Service](keycloak/README.md)