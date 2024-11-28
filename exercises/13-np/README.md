# 🔒 Network Policies w Kubernetes

## 🎯 Cel zadania
Zrozumienie działania Network Policies w Kubernetes poprzez praktyczne ćwiczenia z wykorzystaniem wielu namespace'ów i różnych typów polityk sieciowych.

## 📚 Teoria

### Network Policies w Kubernetes
- Działają jak firewall dla podów
- Kontrolują ruch przychodzący (ingress) i wychodzący (egress)
- Opierają się na etykietach (labels) podów
- Domyślnie: cały ruch jest dozwolony
- Mogą działać w obrębie namespace i między nimi
- Polityki się sumują - wystarczy jedna pozwalająca

### Typy reguł
1. **Deny All Traffic**
   - Blokuje cały ruch do podów
   - Punkt startowy do bardziej szczegółowych polityk
   
2. **Allow Specific Traffic**
   - Zezwala na ruch od konkretnych podów/namespace'ów
   - Bazuje na selektorach i etykietach

## 📝 Zadanie: Network Policies w dwóch namespace'ach

### Krok 1: Utworzenie namespace'ów
```bash
kubectl create ns <login>-prod
kubectl create ns <login>-test
```

### Krok 2: webstore.yaml - Deployment i Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webstore
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webstore
  template:
    metadata:
      labels:
        app: webstore
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
  name: webstore-svc
spec:
  type: ClusterIP
  selector:
    app: webstore
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### Krok 3: deny-all.yaml - Polityka blokująca cały ruch

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all
spec:
  podSelector:
    matchLabels:
      app: webstore
  ingress: []
```

### Krok 4: allow-test.yaml - Polityka zezwalająca na ruch z namespace test

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-test
spec:
  podSelector:
    matchLabels:
      app: webstore
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: <login>-test
```

## 🔨 Wdrożenie:

1. Wdróż aplikację w namespace prod:
```bash
kubectl apply -f webstore.yaml -n <login>-prod
```

2. Oznacz namespace test:
```bash
kubectl label namespace <login>-test name=<login>-test
```

3. Zastosuj politykę deny-all:
```bash
kubectl apply -f deny-all.yaml -n <login>-prod
```

4. Zastosuj politykę allow-test:
```bash
kubectl apply -f allow-test.yaml -n <login>-prod
```

## 🧪 Testowanie polityk:

1. Test z domyślnego namespace (powinien być zablokowany):
```bash
kubectl run test-pod --rm -it --image=alpine -- sh
wget -qO- --timeout=2 http://webstore-svc.<login>-prod
# Powinien wystąpić timeout
```

2. Test z namespace test (powinien działać):
```bash
kubectl run test-pod --rm -it --image=alpine -n <login>-test -- sh
wget -qO- --timeout=2 http://webstore-svc.<login>-prod
# Powinniśmy zobaczyć stronę nginx
```

## 📋 Przydatne komendy diagnostyczne

```bash
# Sprawdź polityki sieciowe
kubectl get networkpolicies -n <login>-prod

# Szczegóły polityki
kubectl describe networkpolicy deny-all -n <login>-prod

# Sprawdź pody i ich etykiety
kubectl get pods --show-labels -n <login>-prod
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Brak dostępu mimo polityki | Sprawdź etykiety podów i namespace'ów |
| Nieoczekiwany dostęp | Sprawdź wszystkie polityki w namespace |
| Timeout przy teście | Upewnij się, że pod testowy ma odpowiednie etykiety |

## ✅ Dobre praktyki

1. **Projektowanie polityk**
   - Zacznij od deny-all
   - Dodawaj precyzyjne reguły
   - Dokumentuj każdą politykę
   
2. **Testowanie**
   - Testuj z różnych namespace'ów
   - Używaj podów testowych
   - Sprawdzaj logi
   
3. **Bezpieczeństwo**
   - Regularnie audytuj polityki
   - Unikaj zbyt szerokich reguł
   - Monitoruj odrzucony ruch

## 🎓 Podsumowanie
- Network Policies to podstawowe narzędzie bezpieczeństwa w K8s
- Umożliwiają precyzyjną kontrolę ruchu
- Działają na podstawie etykiet podów i namespace'ów
- Pozwalają na izolację środowisk (np. prod od test)

## 📚 Przykłady użycia

### Scenariusz: Izolacja środowisk
1. Środowisko produkcyjne:
   - Deny all traffic
   - Allow tylko z określonych źródeł
   
2. Środowisko testowe:
   - Większa swoboda w komunikacji
   - Możliwość testowania nowych polityk

### Scenariusz: Mikrousługi
```bash
# Przykład dla mikrousługi frontend -> backend
kubectl apply -f allow-frontend.yaml -n <login>-prod
```

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```