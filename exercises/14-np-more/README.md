# 🔒 Zaawansowane Network Policies w Kubernetes

## 🎯 Cel zadania
Zrozumienie zaawansowanych aspektów Network Policies, w szczególności izolacji namespace'ów i domyślnych polityk bezpieczeństwa w klastrze Kubernetes.

## 📚 Teoria

### Domyślne polityki w Kubernetes
- Bez Network Policy: cały ruch jest dozwolony
- Najlepsza praktyka: zacznij od blokowania
- Podejście "deny-all, allow-some"
- Polityki mogą być stosowane na poziomie:
  - Pojedynczych podów
  - Całych namespace'ów
  - Wszystkich podów w namespace

### Strategie izolacji
1. **Pełna izolacja namespace**
   - Blokuje cały ruch z innych namespace'ów
   - Pozwala na komunikację wewnątrz namespace
   
2. **Domyślna polityka deny-all**
   - Blokuje cały nieoznaczony ruch
   - Wymaga jawnego zdefiniowania reguł

## 📝 Zadanie 1: Izolacja namespace'ów

### Krok 1: deny-from-other-ns.yaml - Polityka izolująca namespace

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-from-other-ns
  namespace: <login>-prod
spec:
  podSelector: {}  # Pusta = stosuje się do wszystkich podów
  ingress:
  - from:
    - podSelector: {}  # Pozwala na ruch w ramach namespace
```

### Krok 2: default-deny-all.yaml - Domyślna polityka blokująca

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny-all
  namespace: <login>-prod
spec:
  podSelector: {}
  ingress: []  # Puste = blokuje cały ruch
```

## 🔨 Wdrożenie:

1. Wdróż aplikacje testowe w różnych namespace'ach:
```bash
# Namespace produkcyjny
kubectl run web-prod --image=nginx --labels="app=web" --port=80 -n <login>-prod
kubectl expose pod web-prod --port=80 -n <login>-prod

# Namespace testowy
kubectl run web-test --image=nginx --labels="app=web" --port=80 -n <login>-test
kubectl expose pod web-test --port=80 -n <login>-test
```

2. Zastosuj politykę izolacji namespace:
```bash
kubectl apply -f deny-from-other-ns.yaml
```

3. Zastosuj domyślną politykę:
```bash
kubectl apply -f default-deny-all.yaml
```

## 🧪 Testowanie izolacji:

1. Test ruchu z tego samego namespace (powinien działać):
```bash
kubectl run test-pod --rm -it --image=alpine -n <login>-prod -- sh -- sleep 3600
wget -qO- --timeout=2 http://web-prod
# Powinniśmy zobaczyć stronę nginx
```

2. Test ruchu z innego namespace (powinien być zablokowany):
```bash
kubectl run test-pod --rm -it --image=alpine -n <login>-test -- sh -- sleep 3600
wget -qO- --timeout=2 http://web-prod.<login>-prod
# Powinien wystąpić timeout
```

## 📝 Zadanie 2: Selektywne zezwalanie na ruch

### allow-specific-service.yaml - Zezwolenie na ruch do konkretnego serwisu

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-specific-service
  namespace: <login>-prod
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: test
    - podSelector:
        matchLabels:
          role: frontend
```

## 🔨 Wdrożenie i test:

1. Oznacz namespace testowy:
```bash
kubectl label namespace <login>-test environment=test
```

2. Zastosuj politykę:
```bash
kubectl apply -f allow-specific-service.yaml
```

3. Test z oznaczonym podem:
```bash
kubectl run frontend --image=alpine --labels="role=frontend" -n <login>-test -- sleep 3600
kubectl exec -it frontend -n <login>-test -- wget -qO- http://web-prod.<login>-prod
```

## 📋 Komendy diagnostyczne

```bash
# Sprawdź wszystkie polityki w namespace
kubectl get networkpolicies -n <login>-prod

# Sprawdź reguły dla konkretnej polityki
kubectl describe networkpolicy deny-from-other-ns -n <login>-prod

# Sprawdź etykiety namespace'ów
kubectl get namespaces --show-labels
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Niechciana izolacja | Sprawdź kolejność aplikowania polityk |
| Za szeroka polityka | Użyj precyzyjnych selektorów |
| Konflikty polityk | Pamiętaj: polityki się sumują |

## ✅ Dobre praktyki

1. **Izolacja namespace'ów**
   - Domyślnie izoluj namespace produkcyjny
   - Jawnie definiuj dozwolony ruch
   - Dokumentuj wyjątki
   
2. **Projektowanie polityk**
   - Zacznij od najbardziej restrykcyjnej
   - Używaj precyzyjnych selektorów
   - Testuj przed wdrożeniem
   
3. **Zarządzanie**
   - Monitoruj odrzucony ruch
   - Regularnie przeglądaj polityki
   - Używaj opisowych nazw polityk

## 🎓 Podsumowanie
- Network Policies pozwalają na precyzyjną kontrolę ruchu
- Domyślna polityka deny-all to dobry start
- Izolacja namespace'ów zwiększa bezpieczeństwo
- Selektywne zezwalanie na ruch daje kontrolę

## 📚 Scenariusze użycia

### Przykład 1: Środowisko wielonamespace'owe
```bash
# Monitoring może dostać się wszędzie
kubectl label namespace monitoring purpose=monitoring
```

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-monitoring
spec:
  podSelector: {}
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
```

### Przykład 2: Mikroserwisy
```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-frontend-to-backend
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