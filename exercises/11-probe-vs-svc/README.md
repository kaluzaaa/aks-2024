# 🔍 Wpływ Readiness Probe na Service LoadBalancer

## 🎯 Cel zadania
Zrozumienie jak Readiness Probe wpływa na dostępność podów w Service typu LoadBalancer poprzez symulację awarii w aplikacji kuard.

## 📚 Teoria
Readiness Probe w połączeniu z Service kontroluje, które pody otrzymują ruch. Gdy pod nie przejdzie testu readiness, zostaje usunięty z puli endpointów serwisu, ale pozostaje uruchomiony.

## 📝 Zadanie: Testowanie wpływu Readiness na Service

### Krok 1: Deployment i Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 3
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
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 10      # Sprawdzanie co 10 sekund
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: kuard-service
spec:
  type: LoadBalancer
  selector:
    app: kuard
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

### Krok 2: Wdrożenie i Przygotowanie

1. Utwórz zasoby:
```bash
kubectl apply -f kuard-deployment.yaml
```

2. Poczekaj na przydzielenie zewnętrznego IP:
```bash
kubectl get service kuard-service -w
```

### Krok 3: Monitorowanie w osobnych terminalach

Terminal 1 - Monitorowanie endpointów:
```bash
kubectl get endpoints kuard-service -w
```

Terminal 2 - Monitorowanie deploymentu:
```bash
kubectl get deployment kuard-deployment -w
```

Terminal 3 - Szczegóły serwisu:
```bash
watch -n 1 kubectl describe service kuard-service
```

### Krok 4: Symulacja awarii

1. Otwórz UI kuard w przeglądarce używając zewnętrznego IP serwisu (port 80)
2. Przejdź do zakładki "Readiness Probe"
3. Kliknij przycisk "Fail" 10 razy
4. Obserwuj zmiany w każdym z terminali monitorujących

### Co obserwować:

1. **W terminalu endpointów:**
   - Stopniowe usuwanie adresów IP podów z puli endpointów
   - Zmniejszenie liczby dostępnych endpointów

2. **W terminalu deploymentu:**
   - Zmiana liczby dostępnych (READY) podów
   - Status READY powinien się zmniejszać

3. **W terminalu serwisu:**
   - Zmiany w sekcji Endpoints
   - Aktualizacje w Events

## ❗ Ważne obserwacje

1. **Zachowanie podów:**
   - Pody nie są restartowane
   - Pozostają uruchomione, ale są usuwane z puli ruchu

2. **Zachowanie serwisu:**
   - Ruch jest kierowany tylko do zdrowych podów
   - Load balancing działa tylko na podach z pozytywnym wynikiem readiness

3. **Wpływ na aplikację:**
   - Użytkownicy nie widzą błędów
   - Ruch jest automatycznie przekierowywany do działających instancji

## 🎓 Wnioski
- Readiness Probe jest kluczowym mechanizmem kontroli ruchu
- Pozwala na bezpieczne usuwanie podów z puli ruchu bez ich zatrzymywania
- Zapewnia wysoką dostępność aplikacji podczas problemów z pojedynczymi instancjami

## 📊 Przywracanie normalnego stanu

1. W UI kuard kliknij "Clear" na stronie Readiness Probe
2. Obserwuj jak pody wracają do puli endpointów
3. Zwróć uwagę na czas potrzebny do uznania poda za zdrowy (successThreshold)