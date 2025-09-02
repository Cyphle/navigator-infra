# AWS Databases (RDS PostgreSQL + ElastiCache Redis)

Ce dossier contient la configuration Terraform pour créer les bases de données managées sur AWS.

## 🏗️ Ressources créées

### RDS PostgreSQL
- **Ressource** : `aws_db_instance.banana_postgres`
- **Moteur** : PostgreSQL 15.4
- **Instance** : `db.t3.micro` (2 vCPU, 1 GB RAM)
- **Fonction** : Base de données relationnelle principale
- **Configuration** :
  - **Stockage** : 20 GB GP2 avec auto-scaling jusqu'à 100 GB
  - **Chiffrement** : Activé au repos
  - **Backup** : Rétention 7 jours, fenêtre 03:00-04:00
  - **Maintenance** : Dimanche 04:00-05:00
  - **Snapshot final** : Créé avant destruction

### ElastiCache Redis
- **Ressource** : `aws_elasticache_cluster.banana_redis`
- **Moteur** : Redis 7.0
- **Instance** : `cache.t3.micro` (2 vCPU, 0.5 GB RAM)
- **Fonction** : Cache en mémoire pour les sessions et données temporaires
- **Configuration** :
  - **Port** : 6379
  - **Chiffrement** : Activé au repos
  - **Policy mémoire** : `allkeys-lru` (supprime les clés les moins utilisées)

### Subnet Groups
#### RDS Subnet Group
- **Ressource** : `aws_db_subnet_group.banana`
- **Fonction** : Définit les subnets où RDS peut déployer les instances
- **Subnets** : Utilise les 2 subnets privés pour la haute disponibilité

#### ElastiCache Subnet Group
- **Ressource** : `aws_elasticache_subnet_group.banana`
- **Fonction** : Définit les subnets où ElastiCache peut déployer les clusters
- **Subnets** : Utilise les 2 subnets privés pour la haute disponibilité

### Security Groups
#### RDS Security Group
- **Ressource** : `aws_security_group.rds`
- **Fonction** : Contrôle d'accès réseau pour PostgreSQL
- **Règles** :
  - **Entrant** : Port 5432 depuis le cluster EKS uniquement
  - **Sortant** : Tous les ports et protocoles

#### Redis Security Group
- **Ressource** : `aws_security_group.redis`
- **Fonction** : Contrôle d'accès réseau pour Redis
- **Règles** :
  - **Entrant** : Port 6379 depuis le cluster EKS uniquement
  - **Sortant** : Tous les ports et protocoles

### Parameter Group Redis
- **Ressource** : `aws_elasticache_parameter_group.banana`
- **Fonction** : Configuration personnalisée pour Redis
- **Paramètres** :
  - `maxmemory-policy = allkeys-lru` : Gestion automatique de la mémoire

## 🔄 Fonctionnement des ressources entre elles

### Architecture des bases de données et flux de communication

#### 1. **Communication depuis EKS vers RDS PostgreSQL**
```
Pod EKS → Security Group RDS → RDS Instance → Base de données
```

**Détail du processus :**
- Les **pods EKS** initient des connexions vers RDS sur le port 5432
- Le **Security Group RDS** vérifie que la source est le cluster EKS
- L'**instance RDS** accepte la connexion et exécute les requêtes
- La **base de données** traite les requêtes et retourne les résultats

#### 2. **Communication depuis EKS vers ElastiCache Redis**
```
Pod EKS → Security Group Redis → Redis Cluster → Cache mémoire
```

**Détail du processus :**
- Les **pods EKS** se connectent à Redis sur le port 6379
- Le **Security Group Redis** autorise l'accès depuis EKS
- Le **cluster Redis** gère les opérations de cache
- Les **données** sont stockées en mémoire pour un accès rapide

#### 3. **Communication entre bases de données et services AWS**
```
RDS/Redis → CloudWatch → Métriques et logs
RDS → S3 → Backups et snapshots
Redis → VPC → Communication interne
```

**Détail du processus :**
- **CloudWatch** collecte automatiquement les métriques de performance
- **S3** stocke les sauvegardes RDS et les snapshots
- **VPC** gère la communication interne entre services

### Dépendances et ordre de création

#### **Ordre de création Terraform :**
1. **Subnet Groups** : Définissent où placer les bases
2. **Security Groups** : Contrôlent l'accès réseau
3. **Parameter Group Redis** : Configuration avant création du cluster
4. **RDS Instance** : Base PostgreSQL avec toutes les dépendances
5. **Redis Cluster** : Cache Redis avec configuration personnalisée

#### **Dépendances critiques :**
- **RDS Instance** → **Subnet Group** : Placement dans les subnets appropriés
- **RDS Instance** → **Security Group** : Contrôle d'accès réseau
- **Redis Cluster** → **Subnet Group** : Placement dans les subnets
- **Redis Cluster** → **Parameter Group** : Configuration personnalisée
- **Toutes les ressources** → **VPC et subnets** : Infrastructure réseau

### Intégration avec le VPC et EKS

#### **Placement dans les subnets privés :**
- **Avantages de sécurité** : Aucun accès direct depuis Internet
- **Communication interne** : Accès uniquement depuis le cluster EKS
- **Haute disponibilité** : Distribution sur 2 AZ pour la résilience

#### **Utilisation des Security Groups :**
```
EKS Security Group ← Permet → RDS Security Group (Port 5432)
EKS Security Group ← Permet → Redis Security Group (Port 6379)
```

#### **Flux de trafic réseau :**
- **Trafic entrant** : Seulement depuis les pods EKS autorisés
- **Trafic sortant** : Bases de données peuvent accéder à Internet via NAT Gateway
- **Trafic interne** : Communication optimisée via le réseau VPC

### Gestion des performances et ressources

#### **RDS PostgreSQL :**
- **Instance type** : `db.t3.micro` avec burstable performance
- **Stockage** : GP2 avec IOPS provisionnés automatiquement
- **Auto-scaling** : Stockage s'adapte de 20 GB à 100 GB
- **Monitoring** : Métriques CloudWatch en temps réel

#### **ElastiCache Redis :**
- **Instance type** : `cache.t3.micro` optimisé pour le cache
- **Mémoire** : 0.5 GB avec gestion automatique via LRU
- **Performance** : Accès ultra-rapide aux données en mémoire
- **Scalabilité** : Possibilité d'ajouter des nœuds de lecture

### Stratégie de sauvegarde et récupération

#### **RDS PostgreSQL :**
```
Sauvegarde quotidienne → S3 → Rétention 7 jours
Snapshots manuels → S3 → Rétention illimitée
Point-in-time recovery → Logs de transaction
```

#### **ElastiCache Redis :**
```
Pas de sauvegarde automatique → Données temporaires
Snapshot manuel → S3 → Si nécessaire
Replication → Possibilité de répliques de lecture
```

### Monitoring et alerting

#### **Métriques CloudWatch disponibles :**
- **RDS** : CPU, mémoire, connexions, IOPS, latence
- **Redis** : CPU, mémoire, connexions, hits/misses ratio
- **Network** : Trafic entrant/sortant, erreurs de connexion

#### **Logs et événements :**
- **RDS** : Logs de requêtes, erreurs, maintenance
- **Redis** : Logs de performance et d'erreurs
- **Security Groups** : Tentatives de connexion rejetées

### Gestion des mises à jour et maintenance

#### **RDS PostgreSQL :**
- **Mises à jour automatiques** : Pendant la fenêtre de maintenance
- **Reboot planifié** : Notifié à l'avance
- **Downtime minimal** : Généralement quelques minutes
- **Rollback** : Possibilité de revenir à la version précédente

#### **ElastiCache Redis :**
- **Mises à jour manuelles** : Contrôle total sur le timing
- **Maintenance window** : Configurable selon vos besoins
- **Impact** : Possibilité de downtime pendant la mise à jour
- **Planification** : Recommandé pendant les heures creuses

## 🚀 Déploiement

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

## 📋 Variables requises

Créez un fichier `secrets.tfvars` avec :
```hcl
aws_access_key = "VOTRE_ACCESS_KEY"
aws_secret_key = "VOTRE_SECRET_KEY"
aws_region     = "eu-west-3"  # Optionnel, défaut: eu-west-3
db_user        = "VOTRE_USER_DB"
db_password    = "VOTRE_PASSWORD_DB"
redis_user     = "VOTRE_USER_REDIS"
redis_password = "VOTRE_PASSWORD_REDIS"
```

## 🔒 Sécurité

- **Subnets privés** : Aucun accès direct depuis Internet
- **Security Groups** : Accès uniquement depuis le cluster EKS
- **Chiffrement** : Activé au repos pour RDS et ElastiCache
- **IAM** : Pas d'accès direct aux instances, uniquement via l'application

## 💰 Coûts estimés

- **RDS t3.micro** : ~$15/mois
- **ElastiCache t3.micro** : ~$15/mois
- **Stockage RDS** : ~$2/mois pour 20 GB
- **Total estimé** : ~$32/mois

## 📊 Architecture

```
Cluster EKS
    ↓
Security Groups
    ↓
RDS PostgreSQL (subnet privé)
ElastiCache Redis (subnet privé)
```

## 🚨 Dépendances

**IMPORTANT** : Ce module dépend des modules :
- `01-vpc` : Pour les subnets et VPC
- `02-kubernetes` : Pour le security group EKS

**Ordre de déploiement** :
1. VPC
2. EKS
3. Databases

## 🔧 Connexion aux bases

### PostgreSQL
```bash
# Depuis un pod dans EKS
psql -h banana-postgres.xxxxx.eu-west-3.rds.amazonaws.com -U bananauser -d bananadb
```

### Redis
```bash
# Depuis un pod dans EKS
redis-cli -h banana-redis.xxxxx.cache.amazonaws.com -p 6379
```

## 📝 Notes importantes

- **Haute disponibilité** : Les bases sont déployées sur 2 AZ
- **Backup automatique** : RDS fait des sauvegardes quotidiennes
- **Maintenance** : Fenêtres de maintenance configurées
- **Monitoring** : CloudWatch metrics disponibles
- **Logs** : RDS et ElastiCache génèrent des logs de performance

## 🔄 Maintenance

- **RDS** : Mises à jour automatiques pendant la fenêtre de maintenance
- **ElastiCache** : Mises à jour manuelles recommandées
- **Backup** : Rétention configurée à 7 jours
- **Snapshots** : Création automatique avant destruction

## 🔍 Monitoring et surveillance

### **Métriques CloudWatch disponibles :**
- **RDS** : CPU, mémoire, connexions, IOPS, latence
- **Redis** : CPU, mémoire, connexions, hits/misses ratio
- **Network** : Trafic entrant/sortant, erreurs de connexion

### **Logs et événements :**
- **RDS** : Logs de requêtes, erreurs, maintenance
- **Redis** : Logs de performance et d'erreurs
- **Security Groups** : Tentatives de connexion rejetées

## 🚨 Points d'attention

### **Limitations actuelles :**
1. **Instance unique** : Pas de réplication automatique
2. **Stockage limité** : 100 GB maximum pour RDS
3. **Pas de backup Redis** : Données temporaires uniquement

### **Améliorations possibles :**
1. **Multi-AZ RDS** : Haute disponibilité avec failover automatique
2. **Read Replicas** : Performance et scalabilité
3. **Redis Cluster** : Distribution des données sur plusieurs nœuds
4. **Monitoring avancé** : Alertes et dashboards personnalisés
5. **Backup Redis** : Snapshots réguliers si nécessaire
