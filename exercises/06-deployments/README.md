# 🚀 Wprowadzenie do Deployments w Kubernetes

## 🎯 Cel zadania
Celem zadania jest zrozumienie podstaw działania Deployments w Kubernetes - jak je tworzyć, skalować i zarządzać nimi.

## 📚 Teoria

### Deployment w Kubernetes
- **Deployment**: Obiekt Kubernetes zarządzający aplikacjami
- **Repliki**: Kopie tego samego Pod'a działające równolegle
- **Skalowanie**: Możliwość zwiększania lub zmniejszania liczby Pod'ów
- **Deklaratywność**: Opisujemy pożądany stan, Kubernetes dba o jego utrzymanie

## 📝 Zadanie 1: Tworzenie pierwszego Deploymentu

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 1
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
```

### Kroki wdrożenia:

1. Zapisz powyższy YAML do pliku `kuard-deployment.yaml`

2. Wdróż Deployment:
```bash
kubectl apply -f kuard-deployment.yaml
```

3. Sprawdź status:
```bash
kubectl get deployments
```
Zobaczysz:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
kuard-deployment   1/1     1            1           30s
```

```bash
kubectl get pods
```
Zobaczysz:
```
NAME                                READY   STATUS    RESTARTS   AGE
kuard-deployment-66b8f69f4-x2pnr   1/1     Running   0          30s
```

## 📝 Zadanie 2: Skalowanie przez YAML

Zaktualizuj plik YAML zmieniając liczbę replik na 3:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard-deployment
spec:
  replicas: 3  # Zmiana z 1 na 3
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
```

Zastosuj zmiany:
```bash
kubectl apply -f kuard-deployment.yaml
```

Sprawdź rezultat:
```bash
kubectl get deployments
```
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
kuard-deployment   3/3     3            3           2m
```

```bash
kubectl get pods
```
```
NAME                                READY   STATUS    RESTARTS   AGE
kuard-deployment-66b8f69f4-x2pnr   1/1     Running   0          2m
kuard-deployment-66b8f69f4-j9dhf   1/1     Running   0          15s
kuard-deployment-66b8f69f4-k8p9v   1/1     Running   0          15s
```

## 📝 Zadanie 3: Skalowanie przez kubectl

Skalowanie do 1 repliki używając linii komend:
```bash
kubectl scale deployment kuard-deployment --replicas=1
```

Sprawdź rezultat:
```bash
kubectl get deployments
```
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
kuard-deployment   1/1     1            1           5m
```

```bash
kubectl get pods
```
```
NAME                                READY   STATUS    RESTARTS   AGE
kuard-deployment-66b8f69f4-x2pnr   1/1     Running   0          5m
```

## 📋 Podstawowe komendy

```bash
# Wyświetl wszystkie deployments
kubectl get deployments

Zobaczysz wynik podobny do:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
kuard-deployment   3/3     3            3           5m
```

Gdzie:
- READY: Liczba gotowych replik / całkowita liczba replik
- UP-TO-DATE: Liczba replik zaktualizowanych do najnowszej wersji
- AVAILABLE: Liczba dostępnych replik
- AGE: Czas od utworzenia deploymentu

# Wyświetl pody
kubectl get pods

Zobaczysz wynik podobny do:
```
NAME                                READY   STATUS    RESTARTS   AGE
kuard-deployment-66b8f69f4-2pnrx   1/1     Running   0          5m
kuard-deployment-66b8f69f4-8zhv2   1/1     Running   0          5m
kuard-deployment-66b8f69f4-vx9k2   1/1     Running   0          5m
```

# Szczegółowe informacje o deployment
kubectl describe deployment kuard-deployment

# Wyświetl pody należące do deployment
kubectl get pods -l app=kuard

# Usuń deployment
kubectl delete deployment kuard-deployment

# Sprawdź status rollout
kubectl rollout status deployment kuard-deployment

# Wyświetl historię deployment
kubectl rollout history deployment kuard-deployment
```

## ❗ Najczęstsze problemy

| Problem | Rozwiązanie |
|---------|-------------|
| Deployment nie tworzy podów | Sprawdź selector i labels |
| Pody nie startują | Sprawdź dostępność obrazu i zasoby |
| Niewłaściwa liczba replik | Zweryfikuj specyfikację replicas |

## ✅ Dobre praktyki

1. **Zawsze używaj labels**
   - Ułatwiają organizację
   - Umożliwiają filtrowanie
   
2. **Monitoruj stan deploymentu**
   - Regularnie sprawdzaj status
   - Obserwuj liczby replik
   
3. **Dokumentuj konfigurację**
   - Przechowuj pliki YAML w repozytorium
   - Komentuj ważne ustawienia

## 🎓 Podsumowanie
- Deployment zarządza zestawem identycznych Podów
- Możemy skalować aplikację deklaratywnie (YAML) lub imperatywnie (kubectl)
- Kubernetes dba o utrzymanie pożądanej liczby replik
- Podstawowe operacje można wykonywać przez kubectl