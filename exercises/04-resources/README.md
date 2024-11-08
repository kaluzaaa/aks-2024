# 🔧 Zarządzanie zasobami w Kubernetes: Resources, Limits i QoS

## 🎯 Cel zadania
Celem zadania jest zrozumienie jak działają limity zasobów w Kubernetes, co się dzieje gdy pod przekroczy przydzielone limity oraz jak działa Quality of Service (QoS).

## 📚 Teoria

### Resources w Kubernetes
- **Requests**: Minimalna ilość zasobów, której pod potrzebuje
- **Limits**: Maksymalna ilość zasobów, której pod nie może przekroczyć
- **CPU**: Mierzony w jednostkach CPU (1 CPU = 1 vCPU/Core)
  - Można używać milicore (m), np. 100m = 0.1 CPU
- **Memory**: Mierzona w bajtach
  - Można używać sufixów: Ki, Mi, Gi
  - Przykład: 256Mi, 1Gi

#### Quality of Service (QoS) Classes
1. **Guaranteed**
   - Requests = Limits dla CPU i pamięci
   - Najwyższy priorytet, najmniejsza szansa na usunięcie
   
2. **Burstable**
   - Requests < Limits
   - Średni priorytet
   
3. **BestEffort**
   - Brak zdefiniowanych Requests i Limits
   - Najniższy priorytet, pierwsze do usunięcia

## 📝 Zadanie 1: Pod z gwarantowanymi zasobami (QoS: Guaranteed)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-guaranteed
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "100m"
```

## 📝 Zadanie 2: Pod z elastycznymi zasobami (QoS: Burstable)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-burstable
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
```

## 📝 Zadanie 3: Pod bez limitów (QoS: BestEffort)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-besteffort
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
```

## 📝 Zadanie 4: Test OOM (Out of Memory)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kuard-oom
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:1
    resources:
      requests:
        memory: "50Mi"
        cpu: "100m"
      limits:
        memory: "100Mi"
        cpu: "200m"
```

### Kroki testowe:

> [!IMPORTANT]  
> Potrzebujesz do tego zadania dwóch terminali

1. Otwórz pierwszy terminal i uruchom monitoring podów:
```bash
kubectl get pods -w
```

2. W drugim terminalu utwórz pod:
```bash
kubectl apply -f kuard-oom.yaml
```

3. Przekieruj port:
```bash
kubectl port-forward pod/kuard-oom 8080:8080
```

4. Otwórz aplikację w przeglądarce (http://localhost:8080)

5. Przejdź do zakładki `Memory`

6. Obserwuj pierwszy terminal z `kubectl get pods -w` i zacznij klikać `Grow` kilka razy, aby zwiększyć zużycie pamięci powyżej 100Mi

7. W pierwszym terminalu zobaczysz:
```
NAME        READY   STATUS    RESTARTS   AGE
kuard-oom   1/1     Running   0          30s
kuard-oom   1/1     Running   1          45s    # Pod został zrestartowany
```

8. Aby zobaczyć szczegóły OOM:
```bash
kubectl describe pod kuard-oom
```

Zobaczysz w Events:
```
Type     Reason     Age   From               Message
----     ------     ----  ----               -------
Normal   Pulled     2m    kubelet            Container image "gcr.io/kuar-demo/kuard-amd64:1" already present on machine
Normal   Created    2m    kubelet            Created container kuard
Normal   Started    2m    kubelet            Started container kuard
Warning  OOMKilled  1m    kubelet            Container kuard was killed due to OOM (Out of Memory)
Normal   Pulling    1m    kubelet            Container image "gcr.io/kuar-demo/kuard-amd64:1" already present on machine
```

## 📊 Sprawdzanie QoS Class

```bash
# Sprawdź QoS Class dla poda
kubectl get pod kuard-guaranteed -o yaml | grep qosClass
kubectl get pod kuard-burstable -o yaml | grep qosClass
kubectl get pod kuard-besteffort -o yaml | grep qosClass
```

## 📋 Events w Kubernetes

### Co to są Events?
Events w Kubernetes to obiekt API, który dostarcza informacji o tym, co dzieje się wewnątrz klastra. Events są automatycznie generowane gdy:
- Pod jest tworzony/usuwany
- Występują błędy (np. OOMKilled)
- Zmienia się stan zasobów
- Następują zmiany w schedulingu
- Występują problemy z pull'owaniem obrazów

### Podstawowe komendy
```bash
# Pokaż wszystkie wydarzenia w klastrze
kubectl get events

# Pokaż wydarzenia posortowane od najnowszych
kubectl get events --sort-by=.metadata.creationTimestamp

# Pokaż wydarzenia w czasie rzeczywistym
kubectl get events -w

# Pokaż wydarzenia dla konkretnego namespace
kubectl get events -n <namespace>

# Pokaż wydarzenia związane z konkretnym podem
kubectl get events --field-selector involvedObject.name=<pod-name>

# Pokaż wydarzenia z ostatnich 5 minut
kubectl get events --since=5m

# Format wyjścia jako tabela z wybranymi kolumnami
kubectl get events --output=custom-columns=TIMESTAMP:.metadata.creationTimestamp,TYPE:.type,REASON:.reason,MESSAGE:.message
```

### Przykład monitorowania OOM przez Events

1. Uruchom monitoring eventów w pierwszym terminalu:
```bash
kubectl get events -w --field-selector involvedObject.name=kuard-oom
```

2. W drugim terminalu utwórz pod i wykonaj test OOM z poprzedniego zadania.

3. Zobaczysz sekwencję eventów:
```
LAST SEEN   TYPE     REASON      OBJECT          MESSAGE
0s          Normal   Scheduled   pod/kuard-oom   Successfully assigned default/kuard-oom to node1
1s          Normal   Pulling     pod/kuard-oom   Pulling image "gcr.io/kuar-demo/kuard-amd64:1"
10s         Normal   Pulled      pod/kuard-oom   Successfully pulled image "gcr.io/kuar-demo/kuard-amd64:1"
11s         Normal   Created     pod/kuard-oom   Created container kuard
12s         Normal   Started     pod/kuard-oom   Started container kuard
35s         Warning  OOMKilled   pod/kuard-oom   Container kuard was killed due to OOM (Out of Memory)
36s         Normal   Pulling     pod/kuard-oom   Pulling image "gcr.io/kuar-demo/kuard-amd64:1"
```

### Typy Eventów
- **Normal**: Standardowe operacje (utworzenie poda, pull image)
- **Warning**: Problemy i błędy (OOMKilled, ImagePullBackOff)

### Najczęstsze Reasons w Events
| Reason | Opis |
|--------|------|
| Created | Kontener został utworzony |
| Started | Kontener został uruchomiony |
| Pulled | Obraz został pobrany |
| Failed | Wystąpił błąd |
| Killing | Kontener jest zabijany |
| OOMKilled | Przekroczono limit pamięci |
| BackOff | Problem z uruchomieniem kontenera |
| Unhealthy | Nieudane health checki |

### Dobre praktyki używania Events

1. **Monitoring**
   - Używaj `-w` do monitorowania w czasie rzeczywistym
   - Filtruj events dla konkretnych obiektów
   - Zwracaj uwagę na Warning events

2. **Debugowanie**
   - Sprawdzaj events jako pierwszy krok debugowania
   - Łącz informacje z events z logami podów
   - Używaj `--since` do zawężenia czasowego

3. **Agregacja**
   - Przechowuj events długoterminowo (domyślnie są usuwane po godzinie)
   - Używaj narzędzi jak Prometheus/Grafana do agregacji
   - Ustaw alerty na podstawie critical events

4. **Sortowanie i filtrowanie**
   ```bash
   # Sortowanie po czasie
   kubectl get events --sort-by='.lastTimestamp'
   
   # Sortowanie po typie
   kubectl get events --sort-by='.type'
   
   # Filtrowanie po typie Warning
   kubectl get events --field-selector type=Warning
   
   # Łączenie filtrów
   kubectl get events --field-selector type=Warning,reason=OOMKilled
   ```

### Events w praktyce debugowania OOM

1. **Przed testem**
   ```bash
   # Terminal 1: Monitoring ogólny
   kubectl get pods -w
   
   # Terminal 2: Monitoring eventów
   kubectl get events -w --field-selector involvedObject.name=kuard-oom
   
   # Terminal 3: Port forward i testy
   kubectl port-forward pod/kuard-oom 8080:8080
   ```

2. **Po wystąpieniu OOM**
   ```bash
   # Sprawdź historię eventów
   kubectl get events --field-selector involvedObject.name=kuard-oom --sort-by='.lastTimestamp'
   
   # Sprawdź szczegóły poda
   kubectl describe pod kuard-oom
   ```

3. **Analiza**
   - Sprawdź czas między utworzeniem a OOMKilled
   - Zobacz sekwencję eventów przed OOM
   - Zweryfikuj czy są inne warningi

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Pod ciągle się restartuje | Sprawdź logi i describe pod, prawdopodobnie OOMKilled |
| Pod nie startuje | Sprawdź czy node ma wystarczające zasoby |
| Aplikacja działa wolno | Zwiększ requests/limits dla CPU |
| Pod został usunięty | Sprawdź QoS Class i dostępne zasoby na nodzie |

## ✅ Dobre praktyki

1. **Zawsze definiuj requests i limits**
   - Pomaga w planowaniu zasobów
   - Chroni przed przeciążeniem node'a
   
2. **Monitoruj zużycie zasobów**
   - Używaj narzędzi jak Prometheus i Grafana
   - Regularnie sprawdzaj metryki
   
3. **Dobierz odpowiednią klasę QoS**
   - Dla krytycznych aplikacji używaj Guaranteed
   - Dla mniej ważnych możesz użyć Burstable
   - BestEffort tylko dla najmniej ważnych zadań
   
4. **Testuj limity**
   - Sprawdź jak aplikacja zachowuje się przy różnych limitach
   - Testuj scenariusze OOM
   - Monitoruj restarty podów

## 🎓 Podsumowanie
- Resources pomagają efektywnie zarządzać zasobami klastra
- QoS Classes określają priorytety podów
- OOM Kill chroni node przed przeciążeniem
- Właściwe ustawienie limitów jest kluczowe dla stabilności aplikacji

## 🔍 Co dzieje się podczas OOM Kill?
1. Pod przekracza limit pamięci (100Mi w naszym przykładzie)
2. Kubernetes wykrywa przekroczenie limitu
3. Container runtime zabija proces (OOM Kill)
4. Kubelet wykrywa śmierć kontenera
5. Ze względu na domyślną politykę restartową (Always), pod zostaje zrestartowany
6. W `kubectl get pods -w` widzimy zwiększenie liczby restartów
7. Cały proces jest widoczny w czasie rzeczywistym dzięki fladze `-w`
