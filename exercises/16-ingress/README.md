# 🔧 Ingress w Kubernetes: Kompleksowy przewodnik

## 🎯 Cel zadania
Celem zadania jest zrozumienie jak działa Ingress w Kubernetes, jak konfigurować routing HTTP oraz jak zarządzać ruchem przychodzącym do klastra.

## 📚 Teoria

### Ingress w Kubernetes
```yaml
# Podstawowa struktura Ingress
apiVersion: networking.k8s.io/v1  # Używamy najnowszej wersji API
kind: Ingress
metadata:
  name: example-ingress         # Nazwa zasobu Ingress
spec:
  ingressClassName: nginx       # Określa który kontroler powinien obsługiwać ten Ingress
  rules:                       # Lista reguł routingu
  - host: app.example.com      # Domena dla której stosujemy reguły (opcjonalne)
    http:                      # Definicja reguł HTTP
      paths:                   # Lista ścieżek URL
      - path: /api             # Ścieżka URL
        pathType: Prefix       # Typ dopasowania ścieżki (Prefix, Exact)
        backend:               # Definicja backendu
          service:             # Serwis do którego kierujemy ruch
            name: api-service  # Nazwa serwisu
            port:              # Port serwisu
              number: 80       # Numer portu
```

### Kluczowe elementy:

1. **IngressClassName**:
   ```yaml
   spec:
     ingressClassName: nginx  # Zamiast annotacji używamy pola ingressClassName
   ```
   - Określa który kontroler Ingress powinien obsłużyć tę regułę
   - Zastępuje starszą annotację `kubernetes.io/ingress.class`
   - Musi być zdefiniowany w klastrze odpowiedni IngressClass

2. **Rules (Reguły)**:
   ```yaml
   rules:
   - host: app.example.com   # Domena (opcjonalna)
     http:                   # Sekcja reguł HTTP
       paths:               # Lista ścieżek
   ```
   - Definiują jak kierować ruch
   - Mogą być oparte o hosty i/lub ścieżki
   - Reguły są sprawdzane w kolejności

3. **PathType**:
   ```yaml
   pathType: Prefix  # lub Exact
   ```
   - `Prefix`: Dopasowuje ścieżkę i wszystkie podścieżki (np. /api dopasuje /api/v1, /api/docs)
   - `Exact`: Dopasowuje dokładnie podaną ścieżkę
   
4. **Backend**:
   ```yaml
   backend:
     service:
       name: my-service  # Nazwa serwisu Kubernetes
       port:
         number: 80      # Port serwisu
   ```
   - Określa serwis docelowy
   - Musi istnieć w tym samym namespace co Ingress

5. **Path Rewriting**:
   ```yaml
   metadata:
     annotations:
       nginx.ingress.kubernetes.io/rewrite-target: /$2
   spec:
     rules:
     - http:
         paths:
         - path: /api(/|$)(.*)  # Grupa 1: /api(/|$), Grupa 2: (.*)
   ```
   - Pozwala na zmianę ścieżki przed przekazaniem do serwisu
   - Używa wyrażeń regularnych do przechwytywania części ścieżki

### Jak działa Ingress?

1. **Przepływ ruchu**:
   ```
   Internet -> Ingress Controller -> Ingress Rules -> Service -> Pod
   ```

2. **Proces przetwarzania żądania**:
   - Żądanie trafia do Ingress Controller
   - Sprawdzane są reguły (host i path)
   - Ruch jest kierowany do odpowiedniego Service
   - Service przekazuje ruch do Podów

3. **Kluczowe komponenty**:
   - `IngressClass`: Określa który kontroler obsługuje reguły
   - `Rules`: Definicje routingu (host + path)
   - `Backend`: Serwis docelowy
   - `PathType`: Sposób dopasowania ścieżki (Prefix/Exact)

## 📝 Zadanie 1: Podstawowy Ingress

Utwórz plik `basic-app.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-basic
spec:
  replicas: 3
  selector:
    matchLabels:
      app: echo-basic
  template:
    metadata:
      labels:
        app: echo-basic
    spec:
      containers:
      - image: ealen/echo-server:latest
        name: echo-server
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: echo-basic
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: echo-basic
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-basic
spec:
  ingressClassName: nginx
  rules:
  - host: basic-XX.p.patoarchitekci.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo-basic
            port:
              number: 80
```

### Weryfikacja:
```bash
# Wdrożenie konfiguracji
kubectl apply -f basic-app.yaml

# Sprawdzenie statusu
kubectl get deployment echo-basic
kubectl get service echo-basic
kubectl get ingress echo-basic

# Test poprawności konfiguracji
kubectl get ingress echo-basic
```

## 📝 Zadanie 2: Path-based Routing

Utwórz plik `paths-app.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo-app
  template:
    metadata:
      labels:
        app: echo-app
    spec:
      containers:
      - image: ealen/echo-server:latest
        name: echo-server
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-admin
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo-admin
  template:
    metadata:
      labels:
        app: echo-admin
    spec:
      containers:
      - image: ealen/echo-server:latest
        name: echo-server
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: echo-app
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: echo-app
---
apiVersion: v1
kind: Service
metadata:
  name: echo-admin
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: echo-admin
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-paths
spec:
  ingressClassName: nginx
  rules:
  - host: paths-XX.p.patoarchitekci.io
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: echo-app
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: echo-admin
            port:
              number: 80
```

### Weryfikacja:
```bash
# Wdrożenie
kubectl apply -f paths-app.yaml

# Sprawdzenie endpointów
kubectl get endpoints echo-app
kubectl get endpoints echo-admin

# Test konfiguracji ścieżek
kubectl get ingress echo-paths
kubectl describe ingress echo-paths
```

## 📝 Zadanie 3: URL Rewriting

Utwórz plik `rewrite-app.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo-service
  template:
    metadata:
      labels:
        app: echo-service
    spec:
      containers:
      - image: ealen/echo-server:latest
        name: echo-server
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: echo-service
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: echo-service
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-rewrite
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: rewrite-XX.p.patoarchitekci.io
    http:
      paths:
      - path: /api/abc(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: echo-service
            port:
              number: 80
      - path: /api/xyz(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: echo-service
            port:
              number: 80
```

### Weryfikacja:
```bash
# Wdrożenie
kubectl apply -f rewrite-app.yaml

# Test konfiguracji rewrite
kubectl get ingress echo-rewrite
kubectl describe ingress echo-rewrite
```

## 🔍 Diagnozowanie problemów

### Sprawdzanie stanu Ingress
```bash
# Status ogólny
kubectl get ingress

# Szczegóły konkretnego Ingress
kubectl describe ingress echo-basic

# Sprawdzanie eventów
kubectl get events --field-selector involvedObject.kind=Ingress
```

### Weryfikacja endpointów
```bash
# Sprawdzenie endpointów serwisu
kubectl get endpoints echo-basic

# Sprawdzenie gotowości podów
kubectl get pods -l app=echo-basic

# Logi podów
kubectl logs -l app=echo-basic
```

### Testowanie połączeń
```bash
# Sprawdzenie statusu i konfiguracji Ingress
kubectl get ingress
kubectl get events --field-selector involvedObject.kind=Ingress
```

## ✅ Dobre praktyki

1. **Organizacja ruchu**
   - Jeden Ingress per aplikacja
   - Jasne nazewnictwo hostów i ścieżek
   - Grupowanie powiązanych reguł

2. **Path Routing**
   - Bardziej specyficzne ścieżki przed ogólnymi
   - Używaj PathType: Prefix dla elastyczności
   - Testuj wszystkie ścieżki po zmianach

3. **URL Rewriting**
   - Dokumentuj transformacje URL
   - Testuj edge cases w ścieżkach
   - Sprawdzaj wpływ na aplikację

## ❗ Rozwiązywanie problemów

| Problem | Rozwiązanie |
|---------|-------------|
| 404 Not Found | Sprawdź ścieżki w Ingress i działanie serwisu |
| Zły routing | Zweryfikuj kolejność reguł paths |
| Rewrite nie działa | Sprawdź poprawność regex w path i rewrite-target |
| Host nie działa | Sprawdź DNS i nazwę hosta w regułach |

## 🎓 Podsumowanie
- Ingress to warstwa routingu HTTP w Kubernetes
- Możemy kierować ruch bazując na hoście i ścieżce
- URL rewriting zwiększa elastyczność routingu
- Prawidłowa konfiguracja ingressClassName jest kluczowa