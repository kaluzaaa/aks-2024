# 🔧 Zmienne środowiskowe i ConfigMap w Kubernetes

## 🎯 Cel zadania
Celem zadania jest nauczenie się konfigurowania i zarządzania zmiennymi środowiskowymi w Kubernetes, począwszy od prostych przykładów, aż po zaawansowane użycie ConfigMap.

---

## 📝 Zadanie 1: Podstawowe zmienne środowiskowe

### 1.1. Prosty Pod ze zmiennymi środowiskowymi
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-env
  labels:
    name: kuard
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
    env:
    - name: ENVIRONMENT
      value: "development"
    - name: APP_NAME
      value: "kuard-example"
```

### 1.2. Sprawdzenie zmiennych środowiskowych
```bash
# Utwórz Pod
kubectl apply -f kuard-env.yaml

# Przekieruj port
kubectl port-forward pod/kuard-env 8080:8080
```

> 💡 **Wskazówka**: Otwórz `http://localhost:8080` i przejdź do zakładki "ENV", aby zobaczyć zmienne środowiskowe

### 1.3. Zaawansowane zmienne środowiskowe
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-env-advanced
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
```

---

## 📝 Zadanie 2: Testowanie z BusyBox

### 2.1. Prosty Pod BusyBox z wyświetlaniem zmiennych
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-env
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: busybox
    command: ["echo"]
    args: ["Environment: $(ENVIRONMENT), App: $(APP_NAME)"]
    env:
    - name: ENVIRONMENT
      value: "test"
    - name: APP_NAME
      value: "busybox-test"
```

### 2.2. BusyBox z wieloma komendami
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-env-multi
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "All environment variables:"
        env
        echo "----------------"
        echo "Specific variables:"
        echo "ENVIRONMENT=$ENVIRONMENT"
        echo "APP_NAME=$APP_NAME"
    env:
    - name: ENVIRONMENT
      value: "test"
    - name: APP_NAME
      value: "busybox-multi"
```

```bash
# Zobacz wynik
kubectl logs busybox-env-multi
```

---

## 📝 Zadanie 3: Używanie ConfigMap

### 3.1. Tworzenie ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  ENVIRONMENT: "production"
  DATABASE_URL: "postgres://db:5432"
  API_KEY: "123456789"
  CACHE_ENABLED: "true"
```

### 3.2. Pod używający ConfigMap
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-config
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
    env:
    - name: ENVIRONMENT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: ENVIRONMENT
    - name: DB_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DATABASE_URL
```

### 3.3. Wszystkie zmienne z ConfigMap
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-config-all
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
    envFrom:
    - configMapRef:
        name: app-config
```

---

## 📝 Zadanie 4: ConfigMap z plików

### 4.1. Tworzenie plików konfiguracyjnych
```bash
# Utwórz plik app.properties
cat > app.properties << EOF
environment=production
database.url=postgres://db:5432
api.key=123456789
EOF

# Utwórz plik redis.conf
cat > redis.conf << EOF
maxmemory 2mb
maxmemory-policy allkeys-lru
EOF

# Utwórz plik config.json
cat > config.json << EOF
{
  "database": {
    "host": "db.example.com",
    "port": 5432
  },
  "cache": {
    "enabled": true,
    "ttl": 300
  }
}
EOF
```

### 4.2. Tworzenie ConfigMap z plików
```bash
# Z pojedynczego pliku
kubectl create configmap app-properties --from-file=app.properties

# Z wielu plików
kubectl create configmap app-full-config \
  --from-file=app.properties \
  --from-file=redis.conf \
  --from-file=config.json
```

### 4.3. Pod z zamontowanymi plikami
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-files
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
    volumeMounts:
    - name: config-volume
      mountPath: /config
  volumes:
  - name: config-volume
    configMap:
      name: app-full-config
```

> 💡 **Wskazówka**: Po utworzeniu Pod, możesz sprawdzić zamontowane pliki:
> 1. Wykonaj port-forward: `kubectl port-forward pod/kuard-files 8080:8080`
> 2. Otwórz `http://localhost:8080`
> 3. Przejdź do zakładki "File System Browser"
> 4. Sprawdź zawartość katalogu `/config`

---

## 📝 Zadanie 5: Eksport ConfigMap do YAML

### 5.1. Eksport ConfigMap bez tworzenia obiektu
```bash
# Tworzenie ConfigMap bez wysyłania do klastra (--dry-run) i zapisanie do pliku
kubectl create configmap app-config \
  --from-literal=ENVIRONMENT="production" \
  --from-literal=DATABASE_URL="postgres://db:5432" \
  --from-literal=API_KEY="123456789" \
  --dry-run=client \
  -o yaml > app-config.yaml
```

### 5.2. Eksport ConfigMap z plików bez tworzenia obiektu
```bash
# Z pojedynczego pliku
kubectl create configmap app-properties \
  --from-file=app.properties \
  --dry-run=client \
  -o yaml > app-properties-config.yaml

# Z wielu plików
kubectl create configmap app-full-config \
  --from-file=app.properties \
  --from-file=redis.conf \
  --from-file=config.json \
  --dry-run=client \
  -o yaml > full-config.yaml
```

### 5.3. Przykład wygenerowanego pliku YAML
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: app-config
data:
  API_KEY: "123456789"
  DATABASE_URL: "postgres://db:5432"
  ENVIRONMENT: "production"
```

### 5.4. Konwersja istniejącego ConfigMap do YAML
```bash
# Jeśli ConfigMap już istnieje, możesz go wyeksportować do pliku
kubectl get configmap app-config -o yaml > existing-config.yaml

# Usuń niepotrzebne pola zarządzane przez system
# - status
# - creationTimestamp
# - resourceVersion
# - uid
```

### 5.5. Szablon dla nowego ConfigMap
```yaml
# template-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  # Dodaj swoje klucze i wartości tutaj
  APP_NAME: "my-app"
  ENVIRONMENT: "development"
```

### 5.6. Weryfikacja pliku YAML
```bash
# Sprawdź poprawność składni YAML bez tworzenia obiektu
kubectl apply -f app-config.yaml --dry-run=client

# Sprawdź, co zostanie utworzone
kubectl apply -f app-config.yaml --dry-run=client -o yaml
```

---

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Zmienne nie są widoczne | Sprawdź nazwę ConfigMap i klucze |
| Pliki nie są widoczne | Zweryfikuj ścieżkę montowania |
| Błędy w formacie plików | Sprawdź składnię i kodowanie |
| Pod nie startuje | Sprawdź logi: `kubectl describe pod/[nazwa]` |

---

## ✅ Dobre praktyki

1. **Organizacja**
   - Grupuj powiązane zmienne w jednym ConfigMap
   - Używaj opisowych nazw dla zmiennych
   - Trzymaj pliki konfiguracyjne oddzielnie od zmiennych

2. **Bezpieczeństwo**
   - Nie przechowuj haseł w ConfigMap (użyj Secrets)
   - Regularnie przeglądaj zawartość ConfigMap
   - Ogranicz dostęp do wrażliwych konfiguracji

3. **Zarządzanie**
   - Dokumentuj wszystkie zmienne
   - Używaj systemów kontroli wersji
   - Testuj zmiany przed wdrożeniem

4. **Pliki YAML**
   - Używaj znaczących nazw plików
   - Dodawaj komentarze wyjaśniające
   - Standaryzuj format i strukturę