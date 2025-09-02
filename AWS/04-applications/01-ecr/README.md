# AWS ECR (Elastic Container Registry)

Ce dossier contient la configuration Terraform pour créer un registry Docker privé sur AWS via ECR.

## 🏗️ Ressources créées

### Repository ECR
- **Ressource** : `aws_ecr_repository.banana`
- **Nom** : `banana`
- **Fonction** : Registry privé pour stocker les images Docker
- **Configuration** :
  - **Mutabilité des tags** : `MUTABLE` (permet de réécrire les tags)
  - **Scan des images** : Activé automatiquement au push
  - **Chiffrement** : AES256 pour la sécurité des données

### Lifecycle Policy
- **Ressource** : `aws_ecr_lifecycle_policy.banana`
- **Fonction** : Gestion automatique du cycle de vie des images
- **Règles** :
  - **Règle 1** : Garde les 30 dernières images taguées avec préfixe "v"
  - **Règle 2** : Supprime les images non taguées après 14 jours

## 🔄 Fonctionnement des ressources entre elles

### Architecture ECR et flux de données

#### 1. **Cycle de vie des images Docker**
```
Docker Build → Docker Push → ECR Repository → Lifecycle Policy → Nettoyage automatique
```

**Détail du processus :**
- **Docker Build** : Création d'images locales avec `docker build`
- **Docker Push** : Envoi des images vers ECR avec authentification AWS
- **ECR Repository** : Stockage sécurisé avec chiffrement AES256
- **Lifecycle Policy** : Application automatique des règles de nettoyage
- **Nettoyage** : Suppression des anciennes images selon les règles

#### 2. **Intégration avec EKS et autres services AWS**
```
ECR Repository ← Pull → EKS Cluster
ECR Repository ← Scan → Inspector (vulnérabilités)
ECR Repository ← Storage → S3 (stockage des images)
ECR Repository ← IAM → Contrôle d'accès
```

**Détail du processus :**
- **EKS** : Pull des images depuis ECR pour déployer les pods
- **Inspector** : Scan automatique des images pour détecter les vulnérabilités
- **S3** : Stockage des couches d'images avec réplication automatique
- **IAM** : Contrôle d'accès via les politiques et rôles AWS

#### 3. **Flux d'authentification et autorisation**
```
AWS CLI → IAM → ECR → Docker → Push/Pull des images
```

**Détail du processus :**
- **AWS CLI** : Authentification avec vos credentials
- **IAM** : Vérification des permissions sur le repository ECR
- **ECR** : Génération d'un token d'authentification temporaire
- **Docker** : Utilisation du token pour push/pull des images

### Dépendances et ordre de création

#### **Ordre de création Terraform :**
1. **ECR Repository** : Créé en premier avec la configuration de base
2. **Lifecycle Policy** : Attachée au repository existant
3. **IAM Policies** : Configurées pour l'accès au repository

#### **Dépendances critiques :**
- **Lifecycle Policy** → **ECR Repository** : La policy doit référencer un repository existant
- **IAM Access** → **ECR Repository** : Les utilisateurs/services doivent avoir les bonnes permissions
- **EKS Integration** → **ECR Repository** : Le cluster EKS doit pouvoir pull les images

### Intégration avec l'écosystème AWS

#### **Services AWS utilisés par ECR :**
- **S3** : Stockage des couches d'images Docker
- **IAM** : Contrôle d'accès et authentification
- **CloudWatch** : Métriques d'utilisation et logs
- **Inspector** : Scan de sécurité des images
- **CloudTrail** : Audit des actions sur ECR

#### **Communication avec EKS :**
```
EKS Node → IAM Role → ECR → Pull Image → Déploiement Pod
```

**Détail du processus :**
- Les **nœuds EKS** utilisent leur IAM role pour accéder à ECR
- **ECR** vérifie les permissions via IAM
- L'**image** est téléchargée et stockée localement sur le nœud
- Le **pod** est démarré avec l'image locale

### Gestion du cycle de vie des images

#### **Règles de Lifecycle Policy :**
```
Règle 1: Images taguées (v*)
- Condition: Tag commence par "v"
- Action: Garder les 30 dernières
- Impact: Conservation des versions sémantiques

Règle 2: Images non taguées
- Condition: Pas de tag
- Action: Supprimer après 14 jours
- Impact: Nettoyage des images temporaires
```

#### **Avantages de cette approche :**
- **Gestion automatique** : Pas d'intervention manuelle nécessaire
- **Optimisation des coûts** : Suppression des anciennes images
- **Organisation** : Conservation des versions importantes
- **Sécurité** : Suppression des images potentiellement vulnérables

### Performance et optimisation

#### **Stratégies de pull/push :**
- **Pull** : Images mises en cache localement sur les nœuds EKS
- **Push** : Upload incrémental des couches modifiées uniquement
- **Storage** : Utilisation de S3 avec réplication automatique
- **CDN** : Distribution globale des images via CloudFront (optionnel)

#### **Optimisations recommandées :**
- **Multi-stage builds** : Réduction de la taille des images
- **Layer caching** : Réutilisation des couches communes
- **Image tagging** : Utilisation de tags sémantiques (v1.0.0)
- **Cleanup régulier** : Suppression des images obsolètes

### Sécurité et conformité

#### **Chiffrement et protection :**
- **Chiffrement au repos** : AES256 pour toutes les images
- **Chiffrement en transit** : TLS 1.2+ pour les communications
- **IAM** : Contrôle d'accès granulaire via les politiques
- **Scan automatique** : Détection des vulnérabilités avec Inspector

#### **Bonnes pratiques de sécurité :**
- **Principle of least privilege** : Permissions minimales nécessaires
- **Scan régulier** : Vérification des vulnérabilités
- **Tags de sécurité** : Marquage des images sensibles
- **Audit** : Traçabilité complète via CloudTrail

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
```

## 🔧 Utilisation d'ECR

### Authentification
```bash
# Se connecter à ECR
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com
```

### Push d'une image
```bash
# Tagger l'image
docker tag mon-app:latest VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest

# Pousser l'image
docker push VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest
```

### Pull d'une image
```bash
# Récupérer l'image
docker pull VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest
```

## 🔒 Sécurité

- **Repository privé** : Seuls les utilisateurs AWS autorisés peuvent accéder
- **Chiffrement** : Images chiffrées au repos avec AES256
- **IAM** : Contrôle d'accès via les politiques IAM
- **Scan des images** : Détection automatique des vulnérabilités

## 💰 Coûts estimés

- **Stockage** : ~$0.10/GB/mois
- **Transfert de données** : Gratuit pour les transferts internes AWS
- **Scan des images** : Gratuit
- **Total estimé** : ~$1-5/mois selon l'utilisation

## 📊 Architecture

```
Docker Build
    ↓
Docker Push
    ↓
ECR Repository
    ↓
EKS Cluster (pull des images)
```

## 🚨 Dépendances

**IMPORTANT** : Ce module peut être déployé indépendamment des autres modules.

## 🔄 Lifecycle Management

### Règles de nettoyage automatique
1. **Images taguées** : Conservation des 30 dernières versions
2. **Images non taguées** : Suppression après 14 jours
3. **Optimisation** : Réduction automatique des coûts de stockage

### Avantages
- **Économies** : Suppression automatique des anciennes images
- **Organisation** : Maintien d'un historique des versions
- **Sécurité** : Suppression des images potentiellement vulnérables

## 📝 Notes importantes

- **Tags** : Utilisez des tags sémantiques (v1.0.0, v1.0.1, etc.)
- **Images non taguées** : Créées automatiquement lors des builds
- **Scan** : Vérifiez régulièrement les résultats de scan
- **Backup** : ECR ne fait pas de backup automatique des images

## 🔧 Intégration avec EKS

### Dans un Deployment Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mon-app
spec:
  template:
    spec:
      containers:
      - name: mon-app
        image: VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/banana:latest
```

### Pull Secret (optionnel)
```bash
# Créer un secret pour ECR
kubectl create secret docker-registry regcred \
  --docker-server=VOTRE_ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region eu-west-3)
```

## 🚀 Bonnes pratiques

1. **Tags sémantiques** : Utilisez des versions claires (v1.0.0)
2. **Images légères** : Optimisez la taille des images Docker
3. **Scan régulier** : Vérifiez les vulnérabilités
4. **Lifecycle** : Configurez des règles de nettoyage appropriées
5. **Monitoring** : Surveillez l'utilisation et les coûts

## 🔍 Monitoring et surveillance

### **Métriques CloudWatch disponibles :**
- **Repository** : Nombre d'images, taille du stockage
- **API calls** : Push, pull, delete operations
- **Errors** : Échecs d'authentification, permissions refusées

### **Logs et événements :**
- **CloudTrail** : Toutes les actions API sur ECR
- **CloudWatch Logs** : Logs d'activité du repository
- **Inspector** : Résultats des scans de sécurité

## 🚨 Points d'attention

### **Limitations actuelles :**
1. **Scan basique** : Détection limitée des vulnérabilités
2. **Pas de réplication cross-region** : Images stockées dans une seule région
3. **Lifecycle simple** : Règles basiques de nettoyage

### **Améliorations possibles :**
1. **Scan avancé** : Intégration avec des outils de sécurité tiers
2. **Réplication** : Distribution des images sur plusieurs régions
3. **Lifecycle avancé** : Règles de nettoyage plus sophistiquées
4. **Monitoring** : Alertes et dashboards personnalisés
5. **Backup** : Stratégie de sauvegarde des images critiques
