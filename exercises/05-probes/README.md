# 🔍 Sondy w Kubernetes: Liveness i Readiness Probes

## 🎯 Cel zadania
Celem zadania jest zrozumienie jak działają sondy (probes) w Kubernetes, jak je konfigurować oraz jak wpływają na zachowanie aplikacji w klastrze.

## 📚 Teoria

### Sondy w Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-probes
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
    - containerPort: 8080    # Port na którym nasłuchuje aplikacja
    
    # Sprawdza czy aplikacja żyje
    livenessProbe:
      httpGet:                # Typ sondy - HTTP GET
        path: /healthy        # Ścieżka do sprawdzenia
        port: 8080           # Port do sprawdzenia
      initialDelaySeconds: 5  # Opóźnienie pierwszego sprawdzenia
      periodSeconds: 10       # Częstotliwość sprawdzania
      timeoutSeconds: 1       # Timeout na odpowiedź
      successThreshold: 1     # Ile sukcesów przed uznaniem za zdrowe
      failureThreshold: 3     # Ile porażek przed uznaniem za niezdrowe
    
    # Sprawdza czy aplikacja jest gotowa na ruch
    readinessProbe:
      httpGet:
        path: /ready         # Może być inna ścieżka niż dla liveness
        port: 8080
      initialDelaySeconds: 2 # Zwykle mniejsze niż dla liveness
      periodSeconds: 5       # Może być częściej niż liveness
      timeoutSeconds: 1
      successThreshold: 2    # Może wymagać więcej sukcesów
      failureThreshold: 3

    # Przykład TCP Socket probe
    # readinessProbe:
    #   tcpSocket:
    #     port: 8080
    
    # Przykład Exec probe
    # livenessProbe:
    #   exec:
    #     command:           # Komenda do wykonania w kontenerze
    #     - cat
    #     - /tmp/healthy
```

#### Typy sond i ich zastosowanie

1. **HTTP GET**
   - Najczęściej używany typ
   - Sprawdza endpoint HTTP w aplikacji
   - Sukces: kod odpowiedzi 200-399
   - Idealny dla aplikacji webowych
   
2. **TCP Socket**
   - Sprawdza czy port jest otwarty
   - Nie sprawdza stanu aplikacji
   - Dobry dla baz danych, cache'ów
   - Lżejszy niż HTTP GET
   
3. **Exec**
   - Wykonuje komendę w kontenerze
   - Sukces: kod wyjścia = 0
   - Najbardziej elastyczny
   - Większe zużycie zasobów

#### Parametry konfiguracyjne

| Parametr | Opis | Typowa wartość |
|----------|------|----------------|
| initialDelaySeconds | Czas przed pierwszym sprawdzeniem | 5-10s |
| periodSeconds | Częstotliwość sprawdzania | 10-30s |
| timeoutSeconds | Maksymalny czas na odpowiedź | 1-3s |
| successThreshold | Wymagana liczba sukcesów | 1 (liveness), 1-3 (readiness) |
| failureThreshold | Dozwolona liczba porażek | 3 |

### Parametry konfiguracyjne sond
- **initialDelaySeconds**: Czas przed pierwszym sprawdzeniem
- **periodSeconds**: Częstotliwość sprawdzania
- **timeoutSeconds**: Timeout na odpowiedź
- **successThreshold**: Ile sukcesów przed uznaniem za zdrowe
- **failureThreshold**: Ile porażek przed uznaniem za niezdrowe

## 📝 Zadanie 1: Testowanie Liveness Probe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-liveness
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthy
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
```

### Kroki testowe (Liveness):
1. Uruchom pod:
```bash
kubectl apply -f kuard-liveness.yaml
```

2. Przekieruj port:
```bash
kubectl port-forward pod/kuard-liveness 8080:8080
```

3. Otwórz w przeglądarce http://localhost:8080
4. Przejdź do zakładki "Liveness Probe"
5. Kliknij "Fail" aby zasymulować awarię
6. Obserwuj restart poda

## 📝 Zadanie 2: Testowanie Readiness Probe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-readiness
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
      periodSeconds: 5
```

### Kroki testowe (Readiness):
1. Uruchom pod i service:
```bash
kubectl apply -f kuard-readiness.yaml
kubectl expose pod kuard-readiness --port=8080
```

2. W osobnym terminalu obserwuj endpointy:
```bash
kubectl get endpoints kuard-readiness -w
```

3. Przekieruj port i otwórz UI:
```bash
kubectl port-forward pod/kuard-readiness 8080:8080
```

4. Przejdź do zakładki "Readiness Probe"
5. Kliknij "Fail" i obserwuj endpointy

## 📝 Zadanie 3: Pod z obiema sondami

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-combined
  labels:
    app: kuard
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthy
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 2
      periodSeconds: 5
```

### Kroki testowe:

> Potrzebujesz do tego zadania dwóch terminali

1. W pierwszym terminalu uruchom monitoring podów:
```bash
kubectl get pods -w
```

2. W drugim terminalu utwórz pod:
```bash
kubectl apply -f kuard-combined.yaml
```

3. Obserwuj stany poda:
```bash
kubectl describe pod kuard-combined
```

## 📊 Sprawdzanie stanu sond

```bash
# Sprawdź szczegółowe informacje o sondach
kubectl describe pod kuard-combined

# Sprawdź logi pod kątem problemów z sondami
kubectl logs kuard-combined
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Pod nie przechodzi do stanu Ready | Sprawdź Readiness Probe |
| Pod się restartuje | Sprawdź Liveness Probe |
| Długi czas startu aplikacji | Dostosuj initialDelaySeconds |
| Fałszywe alarmy | Zwiększ failureThreshold |

## ✅ Dobre praktyki

1. **Zawsze używaj obu sond**
   - Liveness do wykrywania deadlocków
   - Readiness do kontroli ruchu
   
2. **Właściwe ustawienie timeoutów**
   - initialDelaySeconds dopasowany do czasu startu
   - periodSeconds zależny od znaczenia aplikacji
   
3. **Endpoint /health**
   - Osobny endpoint dla healthchecków
   - Lightweight, bez zależności zewnętrznych
   - Sprawdzanie krytycznych komponentów
   
4. **Monitoring**
   - Śledź historię restartów
   - Monitoruj czas odpowiedzi endpointów health
   - Ustaw alerty na powtarzające się problemy

## 🎯 Przykłady implementacji endpointu health

### Zachowanie sond w różnych scenariuszach

1. **Liveness Probe**
   - Fail → Restart kontenera
   - Nie wpływa na ruch sieciowy
   - Używaj dla wykrywania deadlocków

2. **Readiness Probe**
   - Fail → Usunięcie z endpointów serwisu
   - Nie powoduje restartu
   - Używaj do kontroli ruchu

3. **Obie sondy**
   - Liveness fail → Restart
   - Readiness fail → Brak ruchu
   - Readiness wraca po restarcie

## 🔍 Debugowanie problemów z sondami

### 1. Sprawdzanie logów
```bash
# Logi poda
kubectl logs <pod-name>

# Poprzednie logi (jeśli pod był restartowany)
kubectl logs <pod-name> --previous
```

### 2. Sprawdzanie zdarzeń
```bash
# Wydarzenia związane z podem
kubectl get events --field-selector involvedObject.name=<pod-name>
```

### 3. Szczegółowy opis poda
```bash
kubectl describe pod <pod-name>
```

### 4. Testowanie endpointu health bezpośrednio
```bash
# Port forward
kubectl port-forward <pod-name> 8080:80

# Test endpointu
curl http://localhost:8080/health
```

## 🎓 Podsumowanie
- Sondy są kluczowe dla niezawodności aplikacji
- Liveness sprawdza życie kontenera
- Readiness kontroluje ruch do poda
- Właściwa konfiguracja zapobiega problemom
- Monitoring sond pomaga w debugowaniu

## 🔍 Co się dzieje podczas awarii?

### Scenariusz: Liveness Probe fail
1. Sonda nie otrzymuje poprawnej odpowiedzi
2. Po przekroczeniu failureThreshold
3. Kubernetes restartuje kontener
4. Pod przechodzi przez cykl: Running → Restarting → Running

### Scenariusz: Readiness Probe fail
1. Sonda nie otrzymuje poprawnej odpowiedzi
2. Po przekroczeniu failureThreshold
3. Pod jest usuwany z endpointów serwisu
4. Ruch nie jest kierowany do tego poda
5. Pod pozostaje w stanie Running, ale nie Ready