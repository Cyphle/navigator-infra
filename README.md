# Infrastructure AWS - Projet Banana

Ce dossier contient la configuration Terraform complète pour déployer l'infrastructure AWS équivalente à votre infrastructure Scaleway.

## 🏗️ Architecture globale

```
Internet
    ↓
Internet Gateway
    ↓
Subnet Public (eu-west-3a)
    ↓
NAT Gateway
    ↓
Subnets Privés (eu-west-3a, eu-west-3b)
    ↓
ECS Cluster + Bases de données + ECR
```

## 📁 Structure des modules

### 1. **01-vpc** - Infrastructure réseau
- **VPC** : Réseau privé isolé (10.0.0.0/16)
- **Subnets** : 1 public + 2 privés sur 2 AZ
- **Internet Gateway** : Accès Internet pour le subnet public
- **NAT Gateway** : Accès Internet sortant pour les subnets privés
- **Route Tables** : Configuration du routage réseau

### 2. **02-ecs** - Cluster ECS Fargate
- **Cluster ECS** : Orchestrateur de conteneurs serverless
- **Service ECS** : Déploiement et gestion de l'application
- **Application Load Balancer** : Distribution du trafic
- **Task Definition** : Configuration des conteneurs
- **IAM Roles** : Permissions pour ECS et l'application

### 3. **03-database** - Bases de données managées
- **RDS PostgreSQL** : Base relationnelle (PostgreSQL 15.4)
- **ElastiCache Redis** : Cache en mémoire (Redis 7.0)
- **Subnet Groups** : Placement dans les subnets privés
- **Security Groups** : Accès uniquement depuis ECS

### 4. **04-applications/01-ecr** - Registry Docker
- **ECR Repository** : Registry privé pour images Docker
- **Lifecycle Policy** : Gestion automatique des images
- **Scan automatique** : Détection des vulnérabilités

## 🚀 Ordre de déploiement

**IMPORTANT** : Respectez cet ordre pour éviter les erreurs de dépendances.

```bash
# 1. Déployer le VPC en premier
cd AWS/01-vpc
terraform init
terraform apply -var-file="secrets.tfvars"

# 2. Déployer le cluster ECS
cd ../02-ecs
terraform init
terraform apply -var-file="secrets.tfvars"

# 3. Déployer les bases de données
cd ../03-database
terraform init
terraform apply -var-file="secrets.tfvars"

# 4. Déployer ECR (optionnel, peut être fait en parallèle)
cd ../04-applications/01-ecr
terraform init
terraform apply -var-file="secrets.tfvars"
```

## 📋 Configuration requise

### Prérequis
- **Terraform** : Version >= 1.12.2
- **AWS CLI** : Configuré avec vos credentials
- **GitHub Actions** : Pour le déploiement automatique de l'application

### Variables communes
Créez un fichier `secrets.tfvars` dans chaque dossier avec :
```hcl
aws_access_key = "VOTRE_ACCESS_KEY"
aws_secret_key = "VOTRE_SECRET_KEY"
aws_region     = "eu-west-3"  # Optionnel, défaut: eu-west-3
```

### Variables spécifiques
- **03-database** : Ajoutez `db_user`, `db_password`, `redis_user`, `redis_password`
- **02-ecs** : Variables optionnelles pour personnaliser l'application

## 🔒 Sécurité

### Architecture sécurisée
- **Subnets privés** : Bases de données et tâches ECS isolées d'Internet
- **NAT Gateway** : Accès Internet sortant uniquement
- **Security Groups** : Accès restreint entre services
- **IAM Roles** : Principe du moindre privilège

### Bonnes pratiques
- Utilisez des mots de passe forts pour les bases
- Activez CloudTrail pour l'audit
- Surveillez les accès avec CloudWatch
- Faites des sauvegardes régulières

## 💰 Coûts estimés mensuels

| Service | Coût estimé |
|---------|-------------|
| **VPC** | ~$49 (NAT Gateway + EIP) |
| **ECS Fargate** | ~$45 (Cluster + 2 tâches + ALB) |
| **RDS** | ~$17 (PostgreSQL + stockage) |
| **ElastiCache** | ~$15 (Redis) |
| **ECR** | ~$3 (stockage) |
| **Total** | **~$129/mois** |

*Note : Coûts basés sur une utilisation de développement. Les coûts de production peuvent varier.*

## 🔧 Post-déploiement

### Configuration de l'application
L'application est automatiquement déployée via GitHub Actions :
- **Déclencheurs** : Push sur main/develop ou déclenchement manuel
- **Processus** : Mise à jour de la Task Definition avec la nouvelle image
- **Rollback** : Automatique en cas d'échec du déploiement

### Accès à l'application
```bash
# Récupérer l'URL de l'ALB
aws elbv2 describe-load-balancers \
  --region eu-west-3 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `banana-front`)].DNSName' \
  --output text
```

### Connexion aux bases
```bash
# PostgreSQL
psql -h banana-postgres.xxxxx.eu-west-3.rds.amazonaws.com -U bananauser -d bananadb

# Redis
redis-cli -h banana-redis.xxxxx.cache.amazonaws.com -p 6379
```

### Utilisation d'ECR
```bash
# Authentification
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com

# Push d'image
docker tag mon-app:latest VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest
docker push VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest
```

## 📊 Monitoring et maintenance

### Services AWS utilisés
- **CloudWatch** : Métriques et logs
- **CloudTrail** : Audit des actions API
- **RDS** : Monitoring des bases de données
- **ECS** : Logs et métriques des conteneurs

### Maintenance recommandée
- **Mises à jour** : RDS et ECS se mettent à jour automatiquement
- **Backups** : RDS fait des sauvegardes quotidiennes
- **Nettoyage** : ECR nettoie automatiquement les anciennes images
- **Monitoring** : Surveillez les coûts et performances

## 🚨 Dépannage

### Problèmes courants
1. **Dépendances** : Assurez-vous de déployer dans l'ordre
2. **Credentials** : Vérifiez vos clés AWS
3. **Quotas** : Vérifiez les limites de votre compte AWS
4. **Région** : Tous les modules utilisent `eu-west-3`

### Commandes utiles
```bash
# Vérifier l'état des ressources
terraform state list

# Voir les outputs
terraform output

# Forcer la destruction d'une ressource
terraform destroy -target=aws_instance.example

# Voir les logs Terraform
export TF_LOG=DEBUG
terraform apply
```

## 📝 Notes importantes

- **Haute disponibilité** : Infrastructure déployée sur 2 AZ
- **Sauvegarde** : RDS fait des sauvegardes automatiques
- **Scalabilité** : ECS peut s'adapter à la charge
- **Sécurité** : Architecture en profondeur avec subnets privés
- **Coûts** : Surveillez l'utilisation pour optimiser les coûts
- **Déploiement** : Automatique via GitHub Actions

## 🔗 Liens utiles

- [Documentation AWS Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Guide ECS](https://docs.aws.amazon.com/ecs/)
- [Documentation RDS](https://docs.aws.amazon.com/rds/)
- [Guide ElastiCache](https://docs.aws.amazon.com/elasticache/)
- [Documentation ECR](https://docs.aws.amazon.com/ecr/)
- [GitHub Actions AWS](https://github.com/aws-actions)
