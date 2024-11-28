# 🔄 Strategie Aktualizacji Deploymentów w Kubernetes

## 🎯 Cel zadania
Celem zadania jest zrozumienie różnych strategii aktualizacji Deploymentów w Kubernetes oraz ich praktyczne zastosowanie wraz z probe'ami i zarządzaniem zasobami.

## 📚 Teoria

### Strategie aktualizacji w Kubernetes
- **Recreate**: 
  - Najprostsza strategia
  - Zatrzymuje wszystkie istniejące Pody przed utworzeniem nowych
  - Powoduje przestój aplikacji
  - Dobra dla środowisk testowych lub gdy wymagane jest czysty restart
  
- **RollingUpdate**:
  - Domyślna strategia
  - Stopniowo wymienia stare Pody na nowe
  - Zero-downtime deployment
  - Możliwość konfiguracji przez `maxSurge` i `maxUnavailable`
  - Możliwość cofnięcia w przypadku problemów

### Przykłady konfiguracji strategii:

```yaml
# Strategia Recreate
spec:
  strategy:
    type: Recreate    # Wszystkie pody są usuwane przed utworzeniem nowych

# Strategia RollingUpdate
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Ile dodatkowych podów może być utworzonych ponad desired
      maxUnavailable: 0  # Ile podów może być niedostępnych podczas update
```

## 📝 Zadanie 1: Deployment z Recreate

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 3
  strategy:
    type: Recreate    # Strategia Recreate - wszystkie pody zostaną usunięte przed utworzeniem nowych
  selector:
    matchLabels:
      app: kuard
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - name: kuard
        image: gcr.io/kuar-demo/kuard-amd64:1  # Zaczynamy od wersji 1
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthy
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Kroki wdrożenia:

1. W pierwszym terminalu uruchom monitoring podów:
```bash
kubectl get pods -w
```

2. W drugim terminalu utwórz deployment:
```bash
kubectl apply -f kuard-deployment.yaml
```

3. W drugim terminalu wykonaj aktualizację do wersji 2:
```bash
kubectl set image deployment/kuard-deployment kuard=gcr.io/kuar-demo/kuard-amd64:2
```

4. Sprawdź wersje obrazów:
```bash
kubectl describe pods | grep Image:
```

## 📝 Zadanie 2: Standardowy RollingUpdate - Bezpieczna aktualizacja krocząca

W tym zadaniu wykorzystamy strategię RollingUpdate z maksymalnym bezpieczeństwem - `maxUnavailable=0` oznacza, że zawsze będziemy mieli dostępną pełną liczbę podów, a `maxSurge=1` pozwoli na dodanie jednego dodatkowego poda podczas aktualizacji.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Możemy stworzyć 1 dodatkowy pod
      maxUnavailable: 0  # Nie pozwalamy na niedostępność żadnego poda
  selector:
    matchLabels:
      app: kuard
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - name: kuard
        image: gcr.io/kuar-demo/kuard-amd64:2  # Zaczynamy od wersji 2
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthy
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Kroki testowe:

1. Usuń poprzedni deployment jeśli istnieje:
```bash
kubectl delete deployment kuard-deployment
```

2. W pierwszym terminalu uruchom monitoring:
```bash
kubectl get pods -w
```

3. W drugim terminalu zastosuj konfigurację:
```bash
kubectl apply -f kuard-deployment.yaml
```

4. W drugim terminalu wykonaj aktualizację do wersji 3:
```bash
kubectl set image deployment/kuard-deployment kuard=gcr.io/kuar-demo/kuard-amd64:3
```

5. Sprawdź status aktualizacji:
```bash
kubectl rollout status deployment/kuard-deployment
```

## 📝 Zadanie 3: Szybszy RollingUpdate - Równoległa aktualizacja

W tym zadaniu przyspieszymy proces aktualizacji poprzez pozwolenie na tworzenie większej liczby nowych podów jednocześnie (`maxSurge=2`).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Możemy stworzyć 2 dodatkowe pody
      maxUnavailable: 1  # Jeden pod może być niedostępny
  selector:
    matchLabels:
      app: kuard
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - name: kuard
        image: gcr.io/kuar-demo/kuard-amd64:1
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthy
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Porównanie szybkości obu podejść:

#### Zadanie 2 (Wolniejsze, ale bezpieczniejsze):
- `maxSurge=1`, `maxUnavailable=0`
- W każdym momencie mamy minimum 3 działające pody
- Aktualizacja przebiega sekwencyjnie: +1 nowy, -1 stary
- Dłuższy czas aktualizacji, ale zero downtime
- Wymaga więcej zasobów (przez moment 4 pody)

#### Zadanie 3 (Szybsze, ale bardziej agresywne):
- `maxSurge=2`, `maxUnavailable=1`
- Możemy mieć przez moment tylko 2 działające pody
- Aktualizacja przebiega równolegle: +2 nowe, -1 stary
- Szybszy czas aktualizacji, ale możliwa krótka degradacja wydajności
- Wymaga jeszcze więcej zasobów (przez moment 5 podów)

### Kroki testowe:

1. Usuń poprzedni deployment jeśli istnieje:
```bash
kubectl delete deployment kuard-deployment
```

2. W pierwszym terminalu obserwuj:
```bash
kubectl get pods -w
```

3. W drugim terminalu zastosuj konfigurację:
```bash
kubectl apply -f kuard-deployment.yaml
```

4. W drugim terminalu wykonaj update do wersji 2:
```bash
kubectl set image deployment/kuard-deployment kuard=gcr.io/kuar-demo/kuard-amd64:2
```

5. Sprawdź status aktualizacji:
```bash
kubectl rollout status deployment/kuard-deployment
```

6. Po zakończeniu aktualizacji, wróć do wersji 1:
```bash
kubectl set image deployment/kuard-deployment kuard=gcr.io/kuar-demo/kuard-amd64:1
```

7. Ponownie sprawdź status:
```bash
kubectl rollout status deployment/kuard-deployment
```

### 💡 Który wariant wybrać?

- **Zadanie 2 (wolniejszy)**:
  - Dla krytycznych aplikacji produkcyjnych
  - Gdy nie możemy pozwolić sobie na spadek wydajności
  - Gdy mamy wystarczająco dużo zasobów w klastrze

- **Zadanie 3 (szybszy)**:
  - Dla środowisk deweloperskich/testowych
  - Gdy priorytetem jest szybkość aktualizacji
  - Gdy aplikacja może obsłużyć chwilowy spadek dostępnych instancji

## 📋 Przydatne komendy

```bash
# Sprawdź status rollout
kubectl rollout status deployment/kuard-deployment

# Historia rolloutów
kubectl rollout history deployment/kuard-deployment

# Cofnij ostatni rollout
kubectl rollout undo deployment/kuard-deployment

# Zatrzymaj trwający rollout
kubectl rollout pause deployment/kuard-deployment

# Wznów zatrzymany rollout
kubectl rollout resume deployment/kuard-deployment
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Pody nie startują po update | Sprawdź logi i probe'y |
| Update trwa zbyt długo | Dostosuj `maxSurge` i `maxUnavailable` |
| Problemy z pamięcią | Zweryfikuj resource limits |

## ✅ Dobre praktyki

1. **Zawsze używaj probe'ów**
   - Readiness do kontroli ruchu
   - Liveness do sprawdzania zdrowia
   
2. **Ustawiaj resource limits**
   - Requests dla gwarantowanych zasobów
   - Limits dla maksymalnego użycia
   
3. **Monitoruj proces update'u**
   - Używaj kubectl rollout status
   - Obserwuj logi aplikacji