# AWS EKS (Elastic Kubernetes Service)

Ce dossier contient la configuration Terraform pour créer un cluster Kubernetes managé sur AWS via EKS avec un Application Load Balancer (ALB) comme ingress controller.

## 🏗️ Ressources créées

### Cluster EKS
- **Ressource** : `aws_eks_cluster.banana`
- **Nom** : `banana-cluster`
- **Version Kubernetes** : `1.30`
- **Fonction** : Cluster Kubernetes managé par AWS
- **Configuration** : 
  - Accès privé et public activé
  - Logs d'audit activés (API, audit, authenticator, controllerManager, scheduler)
  - Utilise les subnets publics et privés du VPC

### Node Group EKS
- **Ressource** : `aws_eks_node_group.banana`
- **Nom** : `banana-node-group`
- **Fonction** : Groupe de nœuds worker pour exécuter les pods
- **Configuration** :
  - **Instance type** : `t3.medium` (2 vCPU, 4 GB RAM)
  - **Taille** : 1-2 nœuds avec autoscaling
  - **Subnets** : Uniquement les subnets privés pour la sécurité
  - **Mise à jour** : Maximum 1 nœud indisponible pendant les mises à jour

### Application Load Balancer (ALB)
- **Ressource** : `aws_lb.eks`
- **Nom** : `banana-eks-alb`
- **Fonction** : Load balancer et ingress controller pour EKS
- **Configuration** :
  - **Type** : Application Load Balancer
  - **Subnets** : Subnets publics pour l'accès Internet
  - **Ports** : 80 (HTTP) et 443 (HTTPS)
  - **Tags** : Marqué comme "eks-ingress"

### Target Group pour EKS
- **Ressource** : `aws_lb_target_group.eks`
- **Nom** : `banana-eks-tg`
- **Fonction** : Définit les cibles (nœuds EKS) pour l'ALB
- **Configuration** :
  - **Type** : Instance (pour les nœuds EKS)
  - **Port** : 80
  - **Health Check** : `/` toutes les 30 secondes
  - **Protocol** : HTTP

### Listener ALB
- **Ressource** : `aws_lb_listener.eks`
- **Fonction** : Écoute le trafic sur le port 80 et le route vers le target group
- **Configuration** :
  - **Port** : 80
  - **Protocol** : HTTP
  - **Action** : Forward vers le target group EKS

### Security Groups
#### ALB Security Group
- **Ressource** : `aws_security_group.alb`
- **Fonction** : Contrôle d'accès pour le load balancer
- **Règles** :
  - **Entrant** : Ports 80 et 443 depuis Internet
  - **Sortant** : Tous les ports et protocoles

#### EKS Cluster Security Group
- **Ressource** : `aws_security_group.eks_cluster`
- **Fonction** : Contrôle d'accès réseau pour le cluster
- **Règles** :
  - **Entrant** : Port 443 (HTTPS) depuis partout pour l'API Kubernetes
  - **Sortant** : Tous les ports et protocoles

### IAM Roles et Policies
#### Role Cluster EKS
- **Ressource** : `aws_iam_role.eks_cluster`
- **Fonction** : Permissions pour le service EKS
- **Policies attachées** :
  - `AmazonEKSClusterPolicy` : Permissions de base pour EKS
  - `AmazonEKSVPCResourceController` : Gestion des ressources VPC

#### Role Node Group
- **Ressource** : `aws_iam_role.eks_node_group`
- **Fonction** : Permissions pour les nœuds worker
- **Policies attachées** :
  - `AmazonEKSWorkerNodePolicy` : Permissions de base pour les nœuds
  - `AmazonEKS_CNI_Policy` : Gestion du réseau (CNI)
  - `AmazonEC2ContainerRegistryReadOnly` : Lecture des images ECR

## 🔄 Fonctionnement des ressources entre elles

### Architecture EKS avec ALB et flux de trafic

#### 1. **Flux de trafic entrant via ALB**
```
Internet → ALB (Ports 80/443) → Target Group → Nœuds EKS → Pods Kubernetes
```

**Détail du processus :**
- L'**ALB** reçoit le trafic HTTP/HTTPS sur les ports 80/443
- Le **Target Group** route le trafic vers les nœuds EKS sains
- Les **nœuds EKS** reçoivent le trafic et le distribuent aux pods
- Les **pods Kubernetes** exécutent l'application et répondent

#### 2. **Communication API Kubernetes**
```
Internet → Security Group EKS (Port 443) → API Server EKS → Control Plane AWS
```

**Détail du processus :**
- L'**API Server EKS** écoute sur le port 443 (HTTPS)
- Le **Security Group EKS** autorise le trafic entrant depuis Internet
- Les **subnets publics** permettent l'accès à l'API
- Le **Control Plane AWS** gère l'état du cluster

#### 3. **Gestion des workloads avec ALB**
```
kubectl → API Server → Scheduler → Node Group → Pods → ALB Target Group
```

**Détail du processus :**
- **kubectl** communique avec l'API Server EKS
- Le **Scheduler** décide où placer les pods
- Les **nœuds** reçoivent et exécutent les pods
- L'**ALB** distribue le trafic vers les pods via le target group

### Dépendances et ordre de création

#### **Ordre de création Terraform :**
1. **IAM Roles** : Créés en premier car EKS en a besoin
2. **Security Groups** : Définissent les règles de communication
3. **ALB et Target Group** : Infrastructure de load balancing
4. **Cluster EKS** : Utilise les IAM roles et security groups
5. **Node Group** : Déployé après le cluster et utilise ses ressources

#### **Dépendances critiques :**
- **ALB** → **Security Group ALB** : Contrôle d'accès réseau
- **Target Group** → **VPC** : Placement des cibles
- **Cluster EKS** → **IAM Role Cluster** : Le cluster a besoin des permissions
- **Node Group** → **Cluster EKS** : Les nœuds rejoignent le cluster existant
- **Target Group** → **Nœuds EKS** : Les nœuds sont les cibles du target group

### Intégration avec le VPC

#### **Placement des ressources :**
- **ALB** : Subnets publics pour l'accès Internet
- **Nœuds EKS** : Subnets privés pour la sécurité
- **API Server** : Accessible depuis Internet via subnets publics
- **Security Groups** : Communication contrôlée entre ALB et EKS

#### **Avantages de cette architecture :**
- **Sécurité** : Nœuds dans des subnets privés
- **Accessibilité** : API et ALB accessibles depuis Internet
- **Performance** : Communication interne optimisée via VPC
- **Scalabilité** : ALB distribue automatiquement la charge

### Rôle de l'ALB comme Ingress Controller

#### **Fonctionnalités de l'ALB :**
- **Load Balancing** : Distribution du trafic entre les nœuds EKS
- **Health Checks** : Vérification automatique de la santé des nœuds
- **SSL Termination** : Support HTTPS (à configurer)
- **Path-based Routing** : Routage basé sur les chemins d'URL
- **Host-based Routing** : Routage basé sur les noms d'hôte

#### **Configuration pour Ingress :**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: banana-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: instance
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: banana-service
            port:
              number: 80
```

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

## 🔧 Configuration kubectl

Après le déploiement, configurez kubectl :

```bash
# Mettre à jour le kubeconfig
aws eks update-kubeconfig --region eu-west-3 --name banana-cluster

# Vérifier la connexion
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔒 Sécurité

- **Nœuds dans subnets privés** : Pas d'accès direct depuis Internet
- **ALB dans subnets publics** : Point d'entrée contrôlé pour le trafic applicatif
- **IAM Roles** : Permissions minimales nécessaires
- **Security Groups** : Accès restreint entre ALB et EKS
- **Logs d'audit** : Traçabilité complète des actions

## 💰 Coûts estimés

- **Cluster EKS** : ~$0.10/heure (~$73/mois)
- **Nœuds t3.medium** : ~$0.0416/heure (~$30/mois par nœud)
- **ALB** : ~$16.20/mois
- **Total estimé** : ~$149/mois pour 1 nœud, ~$179/mois pour 2 nœuds

## 📊 Architecture

```
Internet
    ↓
Application Load Balancer (subnets publics)
    ↓
Target Group
    ↓
Nœuds EKS (subnets privés)
    ↓
Pods Kubernetes
    ↓
API Server EKS (subnet public)
```

## 🚨 Dépendances

**IMPORTANT** : Ce module dépend du module VPC (`01-vpc`). Assurez-vous de déployer le VPC en premier.

## 🔄 Autoscaling

Le cluster est configuré avec :
- **Min** : 1 nœud
- **Max** : 2 nœuds
- **Désiré** : 1 nœud
- **Autoscaling** : Activé pour s'adapter à la charge
- **ALB** : Distribution automatique de la charge

## 📝 Notes importantes

- Les nœuds sont déployés dans les subnets privés pour la sécurité
- L'API EKS est accessible depuis Internet pour la gestion
- L'ALB sert de point d'entrée pour les applications
- Les logs d'audit sont activés pour la conformité
- Le cluster utilise la version LTS de Kubernetes (1.30)

## 🔍 Monitoring et surveillance

### **Métriques CloudWatch disponibles :**
- **Cluster EKS** : CPU, mémoire, pods, nœuds
- **Node Group** : Utilisation des ressources par nœud
- **ALB** : Latence, nombre de requêtes, erreurs
- **Target Group** : Health check status, nombre de cibles saines
- **Security Groups** : Trafic réseau, connexions

### **Logs EKS :**
- **API Server** : Toutes les requêtes API
- **Audit** : Actions d'authentification et d'autorisation
- **Controller Manager** : Gestion des contrôleurs
- **Scheduler** : Décisions de placement des pods

## 🚨 Points d'attention

### **Limitations actuelles :**
1. **API publique** : Accessible depuis Internet (peut être restreint)
2. **Nœuds dans une seule AZ** : Pour les subnets privés
3. **ALB HTTP uniquement** : Pas de HTTPS configuré par défaut
4. **Security Group basique** : Règles minimales

### **Améliorations possibles :**
1. **API privée uniquement** : Restriction d'accès à l'API
2. **Nœuds multi-AZ** : Distribution sur plusieurs AZ
3. **HTTPS** : Certificat SSL et ALB en HTTPS
4. **Security Groups avancés** : Règles plus granulaires
5. **Cluster Autoscaler** : Configuration d'autoscaling avancée
6. **Monitoring avancé** : Prometheus, Grafana, etc.
7. **Ingress Controller** : Configuration d'Ingress avec annotations ALB
