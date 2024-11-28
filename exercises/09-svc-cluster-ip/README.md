# 🌐 Service ClusterIP w Kubernetes

## 🎯 Cel zadania
Zrozumienie działania Service typu ClusterIP w Kubernetes poprzez praktyczne ćwiczenie z wykorzystaniem prostego Deploymentu nginx i testowego poda.

## 📚 Teoria

### Service ClusterIP
- Domyślny typ Service w Kubernetes
- Zapewnia wewnętrzną komunikację między podami w klastrze
- Dostępny tylko wewnątrz klastra
- Otrzymuje stały, wewnętrzny adres IP
- Umożliwia load balancing między podami

### Selector - Mechanizm łączenia Service z Podami
- Selector to mechanizm, który określa, które Pody należą do danego Service
- W definicji Service używamy `selector`, który musi odpowiadać `labels` w Podach
- Przykład:
  ```yaml
  # W Service:
  selector:
    app: nginx    # Service szuka Podów z tą etykietą

  # W Pod/Deployment:
  labels:
    app: nginx    # Pod musi mieć tę samą etykietę
  ```
- Dzięki selektorom Service automatycznie wykrywa i kieruje ruch do wszystkich pasujących Podów
- Jeśli dodamy nowy Pod z pasującymi etykietami, Service automatycznie zacznie do niego kierować ruch

## 📝 Krok 1: Deployment nginx

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

## 📝 Krok 2: Service ClusterIP

```yaml
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

## 🔨 Kroki wdrożenia:

1. Utwórz Deployment nginx:
```bash
kubectl apply -f nginx-deployment.yaml
```

2. Sprawdź status podów:
```bash
kubectl get pods -l app=nginx
```

3. Utwórz Service:
```bash
kubectl apply -f nginx-service.yaml
```

4. Sprawdź utworzony Service:
```bash
kubectl get svc nginx-service
```

## 🧪 Testowanie połączenia:

1. Utwórz tymczasowy pod testowy:
```bash
kubectl run test-pod --rm -it --image=giantswarm/tiny-tools -- sh

# Pod zostanie automatycznie usunięty po wyjściu z powłoki (Ctrl+D lub exit)
```

2. Przetestuj połączenie używając nazwy serwisu:
```bash
# Test ping
ping nginx-service

# Test HTTP z pełnymi szczegółami połączenia
curl -v nginx-service
```

3. W nowym terminalu sprawdź IP serwisu:
```bash
# Sprawdź IP serwisu (wykonaj w drugim terminalu)
kubectl get svc nginx-service
# Przykładowe IP: 10.100.71.123
```

4. Wróć do terminala z podem testowym i wykonaj testy:
```bash
# Test ping na IP serwisu
ping 10.100.71.123

# Test HTTP na IP serwisu z pełnymi szczegółami połączenia
curl -v 10.100.71.123
```

## 📋 Przydatne komendy diagnostyczne

```bash
# Sprawdź szczegóły Service
kubectl describe svc nginx-service

# Sprawdź endpointy Service
kubectl get endpoints nginx-service

# Sprawdź logi podów nginx
kubectl logs -l app=nginx

# Sprawdź wydarzenia w klastrze
kubectl get events
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Service nie kieruje ruchu | Sprawdź selector w Service i labels w Podach |
| Brak połączenia z Service | Sprawdź polityki sieciowe i DNS |
| Pod nie odpowiada | Sprawdź logi i stan poda nginx |

## ✅ Dobre praktyki

1. **Zawsze używaj selectorów**
   - Upewnij się, że selector w Service odpowiada labels w Podach
   - Używaj znaczących nazw dla labels

2. **Monitorowanie**
   - Regularnie sprawdzaj endpointy
   - Monitoruj dostępność Service

3. **Dokumentacja**
   - Dokumentuj porty i protokoły używane przez Service
   - Zapisuj zależności między komponentami