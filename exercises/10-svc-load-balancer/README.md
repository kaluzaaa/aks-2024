# 🌐 Service LoadBalancer w Kubernetes na Azure AKS

## 🎯 Cel zadania
Zrozumienie działania Service typu LoadBalancer w Azure AKS poprzez praktyczne ćwiczenia z wykorzystaniem publicznego i wewnętrznego Load Balancera.

## 📚 Teoria

### Service LoadBalancer w Azure AKS
- Rozszerza funkcjonalność ClusterIP
- Automatycznie tworzy Azure Load Balancer
- Zapewnia zewnętrzny dostęp do aplikacji
- Dziedziczy wszystkie funkcje ClusterIP
- Może być skonfigurowany jako publiczny lub wewnętrzny (internal)

### Ważne informacje
- Każdy Service typu LoadBalancer automatycznie otrzymuje ClusterIP
- LoadBalancer rozszerza możliwości ClusterIP o dostęp zewnętrzny
- W przypadku Internal LoadBalancer, dostęp jest ograniczony do sieci VNET

## 📝 Zadanie 1: Publiczny LoadBalancer

### Krok 1: Deployment nginx

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### Krok 2: Public LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-public-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### 🔨 Wdrożenie i testowanie:

1. Utwórz Deployment:
```bash
kubectl apply -f nginx-deployment.yaml
```

2. Utwórz Service:
```bash
kubectl apply -f nginx-public-lb.yaml
```

3. Sprawdź status Service i pobierz publiczny IP:
```bash
kubectl get svc nginx-public-lb -w
```

4. Test dostępu:
- Otwórz przeglądarkę internetową
- Wpisz publiczny IP Load Balancera
- Powinieneś zobaczyć stronę powitalną nginx

## 📝 Zadanie 2: Internal LoadBalancer

### Internal LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-internal-lb
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### 🔨 Wdrożenie i weryfikacja:

1. Utwórz Internal LoadBalancer Service:
```bash
kubectl apply -f nginx-internal-lb.yaml
```

2. Sprawdź status Service:
```bash
kubectl get svc nginx-internal-lb
```

3. Weryfikacja w Azure Portal:
- Przejdź do portalu Azure
- Znajdź grupę zasobów MC_* związaną z klastrem AKS
- Zlokalizuj Load Balancer z typem "Internal"
- Sprawdź konfigurację Frontend IP i Backend Pools

## 📋 Przydatne komendy diagnostyczne

```bash
# Sprawdź szczegóły Service
kubectl describe svc nginx-public-lb
kubectl describe svc nginx-internal-lb

# Sprawdź endpointy
kubectl get endpoints nginx-public-lb
kubectl get endpoints nginx-internal-lb

# Sprawdź wydarzenia w klastrze
kubectl get events
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| LoadBalancer w stanie pending | Sprawdź uprawnienia Service Principal/Managed Identity |
| Brak dostępu do aplikacji | Sprawdź Network Security Groups (NSG) |
| Health probe fails | Zweryfikuj konfigurację health probe w Azure Portal |

## 📚 Przydatne linki
- [Azure Load Balancer Annotations](https://cloud-provider-azure.sigs.k8s.io/topics/loadbalancer/#loadbalancer-annotations)
- [AKS Load Balancer Standard](https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard)
- [AKS Internal Load Balancer](https://learn.microsoft.com/en-us/azure/aks/internal-lb?tabs=set-service-annotations)

## 🎓 Podsumowanie
- LoadBalancer Service zapewnia zewnętrzny dostęp do aplikacji
- Może być skonfigurowany jako publiczny lub wewnętrzny
- Dziedziczy wszystkie funkcje ClusterIP
- Jest integralną częścią infrastruktury Azure