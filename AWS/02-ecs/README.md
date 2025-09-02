# AWS ECS (Elastic Container Service)

Ce dossier contient la configuration Terraform pour créer un cluster ECS Fargate avec déploiement automatique d'application.

## 🏗️ Ressources créées

### Cluster ECS
- **Ressource** : `aws_ecs_cluster.banana`
- **Nom** : `banana-cluster`
- **Fonction** : Cluster ECS pour orchestrer les conteneurs
- **Configuration** : Container Insights activé pour le monitoring

### Task Definition
- **Ressource** : `aws_ecs_task_definition.banana_front`
- **Famille** : `banana-front`
- **Fonction** : Définit comment exécuter l'application
- **Configuration** :
  - **CPU** : 256 (0.25 vCPU)
  - **Mémoire** : 512 MB
  - **Image** : `rg.fr-par.scw.cloud/banana/banana-front:latest`
  - **Port** : 80
  - **Logs** : CloudWatch avec rétention 7 jours

### Service ECS
- **Ressource** : `aws_ecs_service.banana_front`
- **Nom** : `banana-front-service`
- **Fonction** : Gère le déploiement et la scalabilité
- **Configuration** :
  - **Type** : Fargate (serverless)
  - **Instances** : 2 tâches désirées
  - **Subnets** : Subnets privés pour la sécurité
  - **Load Balancer** : Intégré avec ALB

### Application Load Balancer (ALB)
- **Ressource** : `aws_lb.banana_front`
- **Nom** : `banana-front-alb`
- **Fonction** : Distribue le trafic entre les instances
- **Configuration** :
  - **Type** : Application Load Balancer
  - **Subnets** : Subnets publics pour l'accès Internet
  - **Port** : 80 (HTTP)

### Target Group
- **Ressource** : `aws_lb_target_group.banana_front`
- **Fonction** : Définit les cibles (instances ECS)
- **Configuration** :
  - **Type** : IP (pour Fargate)
  - **Port** : 80
  - **Health Check** : `/` toutes les 30 secondes

### Security Groups
#### ALB Security Group
- **Ressource** : `aws_security_group.alb`
- **Fonction** : Contrôle d'accès pour le load balancer
- **Règles** : Port 80 ouvert depuis Internet

#### ECS Service Security Group
- **Ressource** : `aws_security_group.ecs_service`
- **Fonction** : Contrôle d'accès pour les tâches ECS
- **Règles** : Port 80 ouvert uniquement depuis l'ALB

### IAM Roles
#### Execution Role
- **Ressource** : `aws_iam_role.ecs_execution_role`
- **Fonction** : Permissions pour ECS (pull images, logs)
- **Policies** : `AmazonECSTaskExecutionRolePolicy`

#### Task Role
- **Ressource** : `aws_iam_role.ecs_task_role`
- **Fonction** : Permissions pour l'application en cours d'exécution
- **Policies** : Aucune par défaut (à personnaliser selon les besoins)

### CloudWatch Logs
- **Ressource** : `aws_cloudwatch_log_group.banana_front`
- **Fonction** : Stockage des logs de l'application
- **Configuration** : Rétention 7 jours

## 🔄 Fonctionnement des ressources entre elles

### Architecture ECS et flux de trafic

#### 1. **Flux de trafic entrant**
```
Internet → ALB (Port 80) → Target Group → Tâches ECS (Port 80)
```

**Détail du processus :**
- L'**ALB** reçoit le trafic HTTP sur le port 80
- Le **Target Group** route le trafic vers les tâches ECS saines
- Les **tâches ECS** exécutent l'application et répondent

#### 2. **Gestion des tâches ECS**
```
ECS Service → Task Definition → Fargate → Conteneur Docker
```

**Détail du processus :**
- Le **Service ECS** maintient le nombre désiré de tâches
- La **Task Definition** définit la configuration des conteneurs
- **Fargate** provisionne automatiquement les ressources
- Le **conteneur Docker** exécute l'application

#### 3. **Monitoring et logs**
```
Application → CloudWatch Logs → Métriques ECS → Container Insights
```

**Détail du processus :**
- L'**application** génère des logs via stdout/stderr
- **CloudWatch Logs** collecte et stocke les logs
- **ECS** fournit des métriques de performance
- **Container Insights** donne une vue détaillée des ressources

### Dépendances et ordre de création

#### **Ordre de création Terraform :**
1. **IAM Roles** : Permissions nécessaires pour ECS
2. **CloudWatch Log Group** : Pour les logs des conteneurs
3. **Security Groups** : Contrôle d'accès réseau
4. **ALB et Target Group** : Infrastructure de load balancing
5. **Task Definition** : Configuration des conteneurs
6. **ECS Cluster** : Orchestrateur des conteneurs
7. **ECS Service** : Gestion du déploiement

#### **Dépendances critiques :**
- **ECS Service** → **Task Definition** : Le service utilise la définition
- **ECS Service** → **Target Group** : Intégration avec le load balancer
- **Security Groups** → **VPC** : Contrôle d'accès réseau
- **Target Group** → **VPC** : Placement des cibles

### Intégration avec le VPC

#### **Placement des ressources :**
- **ALB** : Subnets publics pour l'accès Internet
- **Tâches ECS** : Subnets privés pour la sécurité
- **Security Groups** : Communication contrôlée entre ALB et ECS

#### **Avantages de cette architecture :**
- **Sécurité** : Tâches isolées dans des subnets privés
- **Scalabilité** : Fargate s'adapte automatiquement à la charge
- **Haute disponibilité** : Distribution sur plusieurs AZ
- **Monitoring** : Logs et métriques centralisés

## 🚀 Déploiement

### Infrastructure (Terraform)
```bash
# Initialiser Terraform
terraform init

# Voir le plan de déploiement
terraform plan -var-file="secrets.tfvars"

# Déployer l'infrastructure
terraform apply -var-file="secrets.tfvars"

# Détruire l'infrastructure
terraform destroy -var-file="secrets.tfvars"
```

### Application (GitHub Actions)
Le déploiement de l'application se fait automatiquement via GitHub Actions :
- **Déclencheurs** : Push sur main/develop ou déclenchement manuel
- **Processus** : Mise à jour de la Task Definition avec la nouvelle image
- **Rollback** : Automatique en cas d'échec du déploiement

## 📋 Variables requises

Créez un fichier `secrets.tfvars` avec :
```hcl
aws_access_key = "VOTRE_ACCESS_KEY"
aws_secret_key = "VOTRE_SECRET_KEY"
aws_region     = "eu-west-3"  # Optionnel, défaut: eu-west-3
```

## 🔧 Configuration GitHub Actions

### Secrets requis dans GitHub :
- `AWS_ACCESS_KEY_ID` : Clé d'accès AWS
- `AWS_SECRET_ACCESS_KEY` : Clé secrète AWS
- `APP_IMAGE` : URL de l'image Docker à déployer

### Variables d'environnement :
- `AWS_REGION` : Région AWS (eu-west-3)
- `ECS_CLUSTER_NAME` : Nom du cluster ECS
- `ECS_SERVICE_NAME` : Nom du service ECS
- `ECS_TASK_DEFINITION_FAMILY` : Famille de la task definition

## 🔒 Sécurité

- **Subnets privés** : Tâches ECS isolées d'Internet
- **Security Groups** : Communication restreinte entre ALB et ECS
- **IAM Roles** : Permissions minimales nécessaires
- **Logs chiffrés** : CloudWatch avec chiffrement automatique

## 💰 Coûts estimés

- **ECS Fargate** : ~$0.04048/heure par tâche (~$29/mois pour 2 tâches)
- **ALB** : ~$16.20/mois
- **Data Processing** : ~$0.10/GB
- **Total estimé** : ~$45/mois

## 📊 Architecture

```
Internet
    ↓
Application Load Balancer (subnet public)
    ↓
Target Group
    ↓
ECS Tasks (subnets privés)
    ↓
Docker Containers
```

## 🚨 Dépendances

**IMPORTANT** : Ce module dépend du module VPC (`01-vpc`). Assurez-vous de déployer le VPC en premier.

## 🔄 Autoscaling

Le service ECS est configuré avec :
- **Désiré** : 2 tâches
- **Autoscaling** : Peut être configuré via CloudWatch et Application Auto Scaling
- **Health Checks** : Vérification automatique de la santé des tâches

## 📝 Notes importantes

- **Fargate** : Pas de gestion des serveurs, AWS gère l'infrastructure
- **Logs** : Automatiquement envoyés vers CloudWatch
- **Monitoring** : Container Insights activé pour une vue détaillée
- **Rollback** : Automatique en cas d'échec du déploiement

## 🔍 Monitoring et surveillance

### **Métriques CloudWatch disponibles :**
- **ECS** : CPU, mémoire, nombre de tâches
- **ALB** : Latence, nombre de requêtes, erreurs
- **Target Group** : Health check status, nombre de cibles saines

### **Logs et événements :**
- **Application** : Logs stdout/stderr des conteneurs
- **ECS** : Événements de déploiement et de scaling
- **ALB** : Logs d'accès et d'erreurs

## 🚨 Points d'attention

### **Limitations actuelles :**
1. **Pas d'autoscaling automatique** : Nombre fixe de tâches
2. **Image externe** : Dépendance sur le registry Scaleway
3. **Pas de HTTPS** : ALB configuré en HTTP uniquement

### **Améliorations possibles :**
1. **Application Auto Scaling** : Basé sur CPU/mémoire
2. **HTTPS** : Certificat SSL et ALB en HTTPS
3. **ECR** : Migration vers le registry AWS ECR
4. **Blue/Green** : Stratégie de déploiement avancée
5. **Monitoring avancé** : Dashboards CloudWatch personnalisés

## 🔧 Utilisation du script de déploiement

### **Déploiement manuel :**
```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Déployer avec une nouvelle image
NEW_IMAGE="rg.fr-par.scw.cloud/banana/banana-front:v1.2.0" ./deploy.sh
```

### **Variables d'environnement :**
- `AWS_REGION` : Région AWS (défaut: eu-west-3)
- `ECS_CLUSTER_NAME` : Nom du cluster (défaut: banana-cluster)
- `ECS_SERVICE_NAME` : Nom du service (défaut: banana-front-service)
- `ECS_TASK_DEFINITION_FAMILY` : Famille de la task definition (défaut: banana-front)
- `NEW_IMAGE` : Nouvelle image Docker à déployer

## 🚀 Bonnes pratiques

1. **Tags** : Utilisez des tags cohérents pour l'organisation
2. **Monitoring** : Surveillez les métriques de performance
3. **Logs** : Configurez la rétention appropriée des logs
4. **Security Groups** : Principe du moindre privilège
5. **IAM** : Permissions minimales nécessaires
6. **Health Checks** : Configurez des health checks appropriés
7. **Rollback** : Testez les procédures de rollback
