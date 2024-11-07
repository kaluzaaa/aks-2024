# 🔐 Secrets i Certyfikaty TLS w Kubernetes

## 🎯 Cel zadania
Celem zadania jest nauczenie się zarządzania wrażliwymi danymi w Kubernetes przy użyciu Secrets oraz generowania i wykorzystywania certyfikatów TLS. Będziemy używać aplikacji kuard, która posiada przyjazny interfejs użytkownika do wizualizacji konfiguracji.

---

## 📝 Zadanie 1: Podstawowe Secrets

### 1.1. Tworzenie prostego Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  username: YWRtaW4=        # base64 encoded 'admin'
  password: cGFzc3dvcmQxMjM= # base64 encoded 'password123'
```

### 1.2. Tworzenie Secret z linii poleceń
```bash
# Tworzenie secret z wartości literalnych
kubectl create secret generic db-secrets \
  --from-literal=username=admin \
  --from-literal=password=password123

# Sprawdzenie utworzonego secretu
kubectl get secret db-secrets -o jsonpath='{.data}'
```

### 1.3. Pod wykorzystujący Secrets
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-secrets
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
        name: http
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secrets
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secrets
          key: password
```

```bash
# Uruchom port-forward aby zobaczyć UI
kubectl port-forward pod/kuard-secrets 8080:8080

# Otwórz http://localhost:8080 i przejdź do zakładki "ENV" aby zobaczyć secrets
```

> 💡 **Wskazówka**: Aplikacja kuard udostępnia przyjazne UI na porcie 8080, gdzie możesz zobaczyć zmienne środowiskowe i zamontowane secrets w zakładkach "ENV" i "File System Browser"

### 1.4. Tworzenie i montowanie Secret z plików
```bash
# Tworzenie plików konfiguracyjnych
echo -n "admin" > ./username
echo -n "s3cr3t" > ./password
echo -n "redis.example.com:6379" > ./redis.conf

# Utworzenie Secret z plików
kubectl create secret generic app-config \
  --from-file=./username \
  --from-file=./password \
  --from-file=./redis.conf

# Alternatywnie, można utworzyć Secret z całego katalogu
# kubectl create secret generic app-config --from-file=./config-dir
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-config-files
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
        name: http
    volumeMounts:
    - name: config-vol
      mountPath: "/etc/config"
      readOnly: true
  volumes:
  - name: config-vol
    secret:
      secretName: app-config
      items:                          # Opcjonalne: mapowanie konkretnych kluczy
      - key: redis.conf              # Klucz w Secret
        path: redis/redis.conf       # Ścieżka w kontenerze
      - key: username
        path: auth/username
        mode: 0400                   # Opcjonalne: uprawnienia pliku
```

```bash
# Sprawdź zamontowane pliki
kubectl exec kuard-config-files -- ls -lR /etc/config

# Uruchom port-forward
kubectl port-forward pod/kuard-config-files 8080:8080

# Otwórz http://localhost:8080 i przejdź do "File System Browser"
# aby zobaczyć zamontowane pliki w /etc/config
```

---

## 📝 Zadanie 2: Generowanie i używanie certyfikatów TLS

### 2.1. Generowanie self-signed certyfikatu
```bash
# Tworzenie klucza prywatnego
openssl genrsa -out server.key 2048

# Tworzenie Certificate Signing Request (CSR)
openssl req -new -key server.key -out server.csr -subj "/CN=example.com/O=Test"

# Generowanie self-signed certyfikatu
openssl x509 -req -days 365 \
  -in server.csr \
  -signkey server.key \
  -out server.crt \
  -extensions v3_req \
  -extfile <(echo "[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com")
```

### 2.2. Tworzenie TLS Secret
```bash
# Tworzenie Secret z certyfikatem TLS
kubectl create secret tls example-tls \
  --cert=server.crt \
  --key=server.key
```

### 2.3. Pod z zamontowanym certyfikatem TLS
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-tls
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
        name: http
    volumeMounts:
    - name: tls-certs
      mountPath: "/etc/tls"
      readOnly: true
  volumes:
  - name: tls-certs
    secret:
      secretName: example-tls
```

```bash
# Uruchom port-forward
kubectl port-forward pod/kuard-tls 8080:8080

# Otwórz http://localhost:8080 i przejdź do zakładki "File System Browser"
# Nawiguj do /etc/tls aby zobaczyć zamontowane certyfikaty
```

---

## 📝 Zadanie 3: Zaawansowane użycie Secrets

### 3.1. Montowanie wielu Secrets
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-multi-secrets
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
      - containerPort: 8080
        name: http
    volumeMounts:
    - name: tls-certs
      mountPath: "/etc/tls"
      readOnly: true
    - name: app-secrets
      mountPath: "/etc/app-secrets"
      readOnly: true
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secrets
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secrets
          key: password
  volumes:
  - name: tls-certs
    secret:
      secretName: example-tls
  - name: app-secrets
    secret:
      secretName: app-secrets
```

```bash
# Uruchom port-forward
kubectl port-forward pod/kuard-multi-secrets 8080:8080

# Otwórz http://localhost:8080 i eksploruj:
# - Zakładka "ENV" dla zmiennych środowiskowych z secrets
# - Zakładka "File System Browser" dla zamontowanych plików
```

---

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Secret nie jest widoczny w UI kuard | Sprawdź ścieżkę montowania i uprawnienia |
| Błąd certyfikatu TLS | Zweryfikuj format i zawartość certyfikatu |
| Problem z base64 | Użyj `-w 0` dla prawidłowego kodowania |
| Pod nie startuje | Użyj `kubectl describe pod/[nazwa]` |
| Problemy z uprawnieniami plików | Sprawdź mode w sekcji items |

---

## ✅ Dobre praktyki

1. **Bezpieczeństwo**
   - Nigdy nie przechowuj Secrets w repozytorium
   - Używaj RBAC do ograniczenia dostępu
   - Regularnie rotuj certyfikaty i hasła
   - Używaj szyfrowania etcd dla dodatkowej ochrony

2. **Organizacja**
   - Grupuj powiązane dane w jednym Secret
   - Używaj opisowych nazw
   - Dokumentuj strukturę i przeznaczenie Secrets

3. **Certyfikaty TLS**
   - Zawsze używaj SAN (Subject Alternative Names)
   - Monitoruj daty wygaśnięcia certyfikatów
   - Przechowuj kopie zapasowe kluczy w bezpiecznym miejscu

4. **Zarządzanie**
   - Automatyzuj proces rotacji Secrets
   - Używaj zewnętrznych systemów zarządzania kluczami (KMS)
   - Regularnie audytuj używane Secrets

---

## 🔍 Weryfikacja i testowanie

### 1. Sprawdzanie Secrets przez UI
```bash
# Uruchom port-forward dla dowolnego pod z kuard
kubectl port-forward pod/kuard-secrets 8080:8080

# Otwórz http://localhost:8080 w przeglądarce i sprawdź:
# - Zakładka "ENV" - zmienne środowiskowe
# - Zakładka "File System Browser" - zamontowane pliki
# - Zakładka "Memory" - użycie pamięci
```

### 2. Weryfikacja przez kubectl
```bash
# Lista wszystkich Secrets
kubectl get secrets

# Dekodowanie Secret
kubectl get secret app-secrets -o jsonpath='{.data.username}' | base64 --decode
```