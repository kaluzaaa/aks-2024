# 🚀 Konfiguracja zaawansowanego Deploymentu w Kubernetes

## 🎯 Cel zadania
Celem zadania jest stworzenie pełnej konfiguracji Deployment wykorzystującej poznane wcześniej elementy konfiguracyjne.

## 📚 Wymagana wiedza z modułów
- [01 - Pod w Kubernetes](/exercises/01-pod/README.md)
- [02 - ConfigMap w Kubernetes](/exercises/02-config/README.md)
- [03 - Secrets w Kubernetes](/exercises/03-secrets/README.md)
- [04 - Resources, Limits i QoS](/exercises/04-resources/README.md)
- [05 - Probes w Kubernetes](/exercises/05-probes/README.md)

## 📝 Zadanie: Deployment z pełną konfiguracją

### 1. Utwórz pliki konfiguracyjne

```bash
# Utwórz plik app.properties
cat > app.properties << EOF
environment=production
database.url=postgres://db:5432
api.key=123456789
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

### 2. Stwórz obiekty w jednym pliku YAML

Utwórz plik `full-config.yaml` zawierający:

1. **ConfigMap** o nazwie `app-config`:
   - Załącz pliki `app.properties` i `config.json`
   - Dodaj zmienną `ENVIRONMENT` z wartością `production`

2. **Secret** o nazwie `app-secrets`:
   - Typ: `Opaque`
   - Zawiera zmienną `DB_PASSWORD` z wartością `admin123`

3. **Deployment** o nazwie `kuard-deployment`:
   - 2 repliki
   - Obraz: `gcr.io/kuar-demo/kuard-amd64:1`
   - QoS Class: Guaranteed (requests = limits)
     - CPU: 100m
     - Memory: 64Mi
   - Health Checks:
     - Liveness probe: endpoint `/healthy`
     - Readiness probe: endpoint `/ready`
     - Oba na porcie 8080
     - InitialDelay: 5s
     - Period: 10s
   - Zmienne środowiskowe:
     - `ENVIRONMENT` z ConfigMap
     - `DB_PASSWORD` z Secret
   - ConfigMap zamontowany jako volumen w `/config`

> 💡 **Wskazówka**: Możesz umieścić wszystkie obiekty w jednym pliku YAML, oddzielając je `---`

## 🔍 Weryfikacja

1. Zastosuj konfigurację:
```bash
kubectl apply -f full-config.yaml
```

2. Sprawdź działanie przez UI kuard:
```bash
kubectl port-forward deployment/kuard-deployment 8080:8080
```

3. Otwórz `http://localhost:8080` i sprawdź:
   - Zakładka "ENV" - zmienne środowiskowe
   - Zakładka "File System Browser" - pliki w `/config`
   - Zakładka "Liveness" i "Readiness" - status probe

## ✅ Kryteria sukcesu
1. Deployment uruchamia 2 repliki
2. QoS Class: Guaranteed (widoczne w `kubectl describe pod`)
3. Oba pliki konfiguracyjne widoczne w `/config`
4. Obie zmienne środowiskowe dostępne
5. Health checki przechodzą pomyślnie