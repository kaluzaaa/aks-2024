# 🔍 DNS i Service Discovery w Kubernetes

## 🎯 Cel zadania
Zrozumienie działania DNS i Service Discovery w Kubernetes poprzez praktyczne ćwiczenia z wykorzystaniem wielu namespace'ów i testowanie resolwingu DNS.

## 📚 Teoria

### DNS w Kubernetes
- Każdy Service otrzymuje wpis DNS w klastrze
- Format nazwy DNS: `<service-name>.<namespace>.svc.cluster.local`
- Dostępne skrócone formy:
  - W tym samym namespace: `<service-name>`
  - Z innego namespace: `<service-name>.<namespace>`
- CoreDNS jest domyślnym serwerem DNS w Kubernetes
- Każdy Pod automatycznie korzysta z DNS klastra

### Service Discovery
- Automatyczne wykrywanie serwisów w klastrze
- Niezależność od konkretnych IP adresów
- Możliwość komunikacji między namespace'ami
- Load balancing na poziomie DNS

## 📝 Zadanie: Deployment i Service w dwóch namespace'ach

### Krok 1: Utworzenie drugiego namespace
```bash
kubectl create ns <login>-2
```

### Krok 2: nginx.yaml - Deployment i Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
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
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

## 🔨 Wdrożenie:

1. Wdróż komponenty w swoim namespace:
```bash
kubectl apply -f nginx.yaml -n <login>
```

2. Wdróż te same komponenty w drugim namespace:
```bash
kubectl apply -f nginx.yaml -n <login>-2
```

## 🧪 Testowanie DNS:

1. Uruchom pod testowy w swoim namespace:
```bash
kubectl run test-pod --rm -it --image=giantswarm/tiny-tools -n <login> -- sh
```

2. Testowanie DNS w twoim namespace:
```bash
# Krótka nazwa (w tym samym namespace)
nslookup nginx-service

# Pełna nazwa
nslookup nginx-service.<login>.svc.cluster.local
```

3. Testowanie DNS z drugiego namespace:
```bash
# Krótka nazwa z namespace
nslookup nginx-service.<login>-2

# Pełna nazwa
nslookup nginx-service.<login>-2.svc.cluster.local
```

## 📋 Przydatne komendy diagnostyczne

```bash
# Sprawdź serwisy w obu namespace'ach
kubectl get svc -n <login>
kubectl get svc -n <login>-2

# Sprawdź DNS dla poda
kubectl exec -n <login> test-pod -- cat /etc/resolv.conf

# Sprawdź logi CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| DNS nie działa | Sprawdź CoreDNS w namespace kube-system |
| Timeout przy nslookup | Sprawdź polityki sieciowe |
| Service niedostępny | Sprawdź nazwę i namespace |

## ✅ Dobre praktyki

1. **Nazewnictwo**
   - Używaj czytelnych nazw serwisów
   - Zachowaj spójną konwencję nazw
   
2. **Namespace**
   - Grupuj powiązane serwisy w namespace'ach
   - Używaj namespace'ów do izolacji
   
3. **Testowanie**
   - Regularnie testuj DNS resolution
   - Sprawdzaj dostępność między namespace'ami

## 🎓 Podsumowanie
- DNS jest kluczowym elementem Service Discovery
- Każdy Service ma unikalną nazwę DNS
- Możliwa komunikacja między namespace'ami
- CoreDNS zapewnia resolving nazw w klastrze

## 📚 Przykłady DNS w różnych namespace'ach

### Format nazw DNS
1. W tym samym namespace `<login>`:
   - `nginx-service`
   
2. Z drugiego namespace:
   - `nginx-service.<login>-2`
   
3. Pełne nazwy (FQDN):
   - `nginx-service.<login>.svc.cluster.local`
   - `nginx-service.<login>-2.svc.cluster.local`

### Przykłady resolwingu (dla użytkownika "student1")
```bash
# W tym samym namespace
nslookup nginx-service
# równoważne z: nslookup nginx-service.student1.svc.cluster.local

# Z drugiego namespace
nslookup nginx-service.student1-2
# równoważne z: nslookup nginx-service.student1-2.svc.cluster.local
```