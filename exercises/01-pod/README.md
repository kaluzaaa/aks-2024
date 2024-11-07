# Tworzenie i zarządzanie Pod w Kubernetes

## Cel zadania
Celem zadania jest nauczenie się tworzenia i zarządzania podstawowym Pod w Kubernetes przy użyciu różnych metod oraz zrozumienie składni YAML i komend kubectl.

## Zadanie 1: Analiza pliku YAML

Przeanalizuj poniższy plik YAML i zrozum znaczenie każdej linii:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
      - containerPort: 80
```

### Wyjaśnienie poszczególnych linii:

* `apiVersion: v1` - Określa wersję API Kubernetes, którą wykorzystujemy
* `kind: Pod` - Definiuje typ zasobu Kubernetes (Pod)
* `metadata:` - Sekcja z metadanymi
  * `name: nginx` - Nazwa Pod
  * `labels:` - Etykiety do organizacji
    * `name: nginx` - Konkretna etykieta
* `spec:` - Specyfikacja Pod
  * `containers:` - Lista kontenerów
  * `name: nginx` - Nazwa kontenera
  * `image: nginx` - Obraz Docker
  * `resources:` - Definicja zasobów
    * `limits:` - Limity zasobów
      * `memory: "128Mi"` - Limit pamięci
      * `cpu: "500m"` - Limit CPU (500 milicores)
  * `ports:` - Konfiguracja portów
    * `containerPort: 80` - Port kontenera

## Zadanie 2: Tworzenie Pod

### Metoda 1: Używając pliku YAML i kubectl create
1. Zapisz powyższy YAML do pliku `nginx-pod.yaml`
2. Wykonaj komendę:
```bash
kubectl create -f nginx-pod.yaml
```

### Metoda 2: Używając kubectl apply
```bash
kubectl apply -f nginx-pod.yaml
```

### Metoda 3: Używając kubectl run
```bash
kubectl run nginx \
  --image=nginx \
  --labels="name=nginx" \
  --port=80
```

### Porównanie metod create vs apply

| Cecha | create | apply |
|-------|---------|--------|
| Tworzy nowy zasób | ✅ | ✅ |
| Aktualizuje istniejący | ❌ | ✅ |
| Obsługuje YAML | ✅ | ✅ |
| Deklaratywne zarządzanie | ❌ | ✅ |
| Dobre do skryptów | ✅ | ✅ |
| Historia zmian | ❌ | ✅ |

## Zadanie 3: Weryfikacja i zarządzanie

1. Sprawdź status Pod:
```bash
kubectl get pod nginx
```

2. Zobacz szczegółowe informacje:
```bash
kubectl describe pod nginx
```

3. Sprawdź logi Pod:
```bash
kubectl logs nginx
```

4. Wykonaj port-forward aby przetestować dostęp:
```bash
kubectl port-forward nginx 8080:80
```

5. W nowym terminalu sprawdź dostęp:
```bash
curl localhost:8080
```

## Zadanie 4: Testowanie różnic między create i apply

1. Spróbuj ponownie utworzyć Pod używając create:
```bash
kubectl create -f nginx-pod.yaml
```
Zobaczysz błąd: `Error from server (AlreadyExists): pods "nginx" already exists`

2. Zmień limit pamięci w pliku YAML na "256Mi"

3. Spróbuj zaktualizować używając create:
```bash
kubectl create -f nginx-pod.yaml
```
Ponownie zobaczysz błąd, ponieważ create nie może aktualizować istniejących zasobów

4. Zaktualizuj Pod używając apply:
```bash
kubectl apply -f nginx-pod.yaml
```
Tym razem operacja również się nie powiedzie, ponieważ apply potrafi aktualizować istniejące zasoby (ale POD nie może być aktualizowany).

## Zadanie 5: Operacje na kontenerze

### Wykonywanie poleceń w kontenerze
1. Wykonaj pojedyncze polecenie:
```bash
kubectl exec nginx -- ls /usr/share/nginx/html
```

2. Uruchom interaktywną sesję bash:
```bash
kubectl exec -it nginx -- bash
```

### Kopiowanie plików

1. Utwórz lokalny plik testowy:
```bash
echo "Hello from Kubernetes!" > test.txt
```

2. Skopiuj plik do Pod:
```bash
kubectl cp test.txt nginx:/usr/share/nginx/html/test.txt
```

3. Skopiuj plik z Pod na lokalny system:
```bash
kubectl cp nginx:/usr/share/nginx/html/test.txt downloaded-test.txt
```

4. Zweryfikuj zawartość skopiowanego pliku:
```bash
kubectl exec nginx -- cat /usr/share/nginx/html/test.txt
cat downloaded-test.txt
```

## Zadanie 6: Czyszczenie

1. Usuń Pod:
```bash
kubectl delete pod nginx
```

2. Sprawdź, czy Pod został usunięty:
```bash
kubectl get pods
```

## Najczęstsze problemy

1. Problem: Pod w stanie Pending
   Rozwiązanie: Sprawdź zasoby klastra

2. Problem: ImagePullBackOff
   Rozwiązanie: Sprawdź nazwę obrazu

3. Problem: CrashLoopBackOff
   Rozwiązanie: Sprawdź logi Pod