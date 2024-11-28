# 🔒 Network Policies: Kontrola ruchu wychodzącego (Egress)

## 🎯 Cel zadania
Zrozumienie mechanizmów kontroli ruchu wychodzącego (Egress) w Kubernetes za pomocą Network Policies, ze szczególnym uwzględnieniem izolacji aplikacji od zewnętrznego świata.

## 📚 Teoria

### Egress w Kubernetes
- Kontroluje ruch wychodzący z podów
- Pozwala ograniczyć dokąd pody mogą się łączyć
- Kluczowy dla bezpieczeństwa aplikacji
- Domyślnie: cały ruch wychodzący jest dozwolony
- Wymaga włączonej opcji `policyTypes: ["Egress"]`

### Typy ograniczeń Egress
1. **Pełna blokada zewnętrzna**
   - Tylko ruch wewnątrz klastra
   - Dostęp do DNS musi być jawnie dozwolony
   
2. **Selektywny dostęp**
   - Konkretne namespace'y
   - Wybrane porty i protokoły
   - Określone zakresy IP

## 📝 Zadanie 1: Blokada ruchu zewnętrznego

### Krok 1: egress-default-deny.yaml - Blokada całego ruchu wychodzącego

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: <login>-prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []  # Pusta lista = brak reguł = blokada całego ruchu
```

### Krok 2: allow-dns.yaml - Zezwolenie na DNS

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <login>-prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
      - port: 53
        protocol: UDP
      - port: 53
        protocol: TCP
```

## 🔨 Wdrożenie:

1. Przygotuj testową aplikację:
```bash
kubectl create deployment test-app --image=nginx -n <login>-prod --labels="app=test"
kubectl expose deployment test-app --port=80 -n <login>-prod
```

2. Zastosuj polityki:
```bash
kubectl apply -f egress-default-deny.yaml
kubectl apply -f allow-dns.yaml
```

## 🧪 Testowanie polityk:

1. Test połączenia wewnętrznego (powinno działać po dodaniu odpowiedniej polityki):
```bash
# Stwórz testowego poda
kubectl run test-pod --rm -it --image=alpine -n <login>-prod -- sh

# Test DNS
nslookup kubernetes.default.svc.cluster.local

# Test połączenia wewnętrznego
wget -qO- --timeout=2 http://test-app
```

2. Test połączenia zewnętrznego (powinno być zablokowane):
```bash
wget -qO- --timeout=2 http://www.example.com
# Powinien wystąpić timeout
```

## 📝 Zadanie 2: Selektywny dostęp zewnętrzny

### allow-selective-egress.yaml - Zezwolenie na ruch do wybranych celów

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-selective-egress
  namespace: <login>-prod
spec:
  podSelector:
    matchLabels:
      app: test
  policyTypes:
  - Egress
  egress:
  # Reguła 1: Dostęp do DNS
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
  # Reguła 2: Dostęp do określonych endpointów zewnętrznych
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.10.0.0/16
    ports:
    - port: 80
      protocol: TCP
    - port: 443
      protocol: TCP
```

## 📋 Przydatne komendy diagnostyczne

```bash
# Sprawdź polityki egress
kubectl get networkpolicies -n <login>-prod

# Sprawdź szczegóły polityki
kubectl describe networkpolicy default-deny-egress -n <login>-prod

# Sprawdź logi podów
kubectl logs -n <login>-prod -l app=test
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| DNS nie działa | Sprawdź politykę allow-dns |
| Aplikacja nie może pobrać obrazów | Dodaj regułę dla registry |
| Częściowa blokada | Sprawdź CIDR w regułach |

## ✅ Dobre praktyki

1. **DNS**
   - Zawsze zezwalaj na DNS dla podów
   - Używaj kube-dns z kube-system
   
2. **Bezpieczeństwo**
   - Zacznij od deny-all
   - Dodawaj minimalne wymagane reguły
   - Dokumentuj wyjątki
   
3. **Monitoring**
   - Śledź zablokowane połączenia
   - Monitoruj próby połączeń
   - Regularnie audytuj reguły

## 🎓 Podsumowanie
- Egress policies są kluczowe dla bezpieczeństwa
- DNS wymaga specjalnej konfiguracji
- Można łączyć różne typy reguł
- Warto zacząć od najbardziej restrykcyjnej polityki

## 📚 Przykłady użycia

### Scenariusz 1: Aplikacja wewnętrzna
- Blokada całego ruchu zewnętrznego
- Dostęp tylko do serwisów w klastrze
- Dozwolony DNS

### Scenariusz 2: Aplikacja z ograniczonym dostępem
- Dostęp do określonych zewnętrznych serwisów
- Blokada pozostałego ruchu
- Monitoring prób połączeń

```yaml
# Przykład monitorowania określonej aplikacji
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitor-egress
  namespace: <login>-prod
spec:
  podSelector:
    matchLabels:
      app: monitored
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - port: 80
    - port: 443
```