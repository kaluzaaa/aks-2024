#!/bin/bash

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Podsumowanie zasobów dla całego klastra ===${NC}"

# Funkcja do konwersji jednostek na milicore/MiB
convert_cpu() {
    local cpu=$1
    if [[ $cpu == *"m" ]]; then
        echo ${cpu%m}
    else
        echo $(bc <<< "${cpu}*1000")
    fi
}

convert_memory() {
    local mem=$1
    if [[ $mem == *"Gi" ]]; then
        echo $(bc <<< "${mem%Gi}*1024")
    elif [[ $mem == *"Mi" ]]; then
        echo ${mem%Mi}
    elif [[ $mem == *"Ki" ]]; then
        echo $(bc <<< "${mem%Ki}/1024")
    else
        echo $(bc <<< "${mem}/1048576") # konwersja z bajtów na MiB
    fi
}

# Inicjalizacja zmiennych dla całego klastra
total_cpu_requests=0
total_cpu_limits=0
total_memory_requests=0
total_memory_limits=0

# Pobierz wszystkie namespace'y
namespaces=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")

echo -e "\n${GREEN}Szczegóły per namespace:${NC}"
printf "%-30s %-15s %-15s %-15s %-15s\n" "NAMESPACE" "CPU REQ" "CPU LIM" "MEM REQ" "MEM LIM"
echo "--------------------------------------------------------------------------------"

for ns in $namespaces; do
    # Inicjalizacja zmiennych dla namespace
    ns_cpu_requests=0
    ns_cpu_limits=0
    ns_memory_requests=0
    ns_memory_limits=0
    
    # Pobierz wszystkie pody w namespace z ich zasobami
    while IFS="," read -r cpu_req cpu_lim mem_req mem_lim; do
        if [ ! -z "$cpu_req" ]; then
            value=$(convert_cpu "$cpu_req")
            ns_cpu_requests=$((ns_cpu_requests + value))
        fi
        
        if [ ! -z "$cpu_lim" ]; then
            value=$(convert_cpu "$cpu_lim")
            ns_cpu_limits=$((ns_cpu_limits + value))
        fi
        
        if [ ! -z "$mem_req" ]; then
            value=$(convert_memory "$mem_req")
            ns_memory_requests=$((ns_memory_requests + value))
        fi
        
        if [ ! -z "$mem_lim" ]; then
            value=$(convert_memory "$mem_lim")
            ns_memory_limits=$((ns_memory_limits + value))
        fi
    done < <(kubectl get pods -n "$ns" -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.resources.requests.cpu},{.resources.limits.cpu},{.resources.requests.memory},{.resources.limits.memory}{"\n"}{end}{end}')
    
    # Wyświetl podsumowanie dla namespace
    printf "%-30s %-15s %-15s %-15s %-15s\n" \
        "$ns" \
        "${ns_cpu_requests}m" \
        "${ns_cpu_limits}m" \
        "${ns_memory_requests}Mi" \
        "${ns_memory_limits}Mi"
    
    # Dodaj do sum całkowitych
    total_cpu_requests=$((total_cpu_requests + ns_cpu_requests))
    total_cpu_limits=$((total_cpu_limits + ns_cpu_limits))
    total_memory_requests=$((total_memory_requests + ns_memory_requests))
    total_memory_limits=$((total_memory_limits + ns_memory_limits))
done

echo -e "\n${RED}Podsumowanie całego klastra:${NC}"
printf "%-30s %-15s %-15s %-15s %-15s\n" \
    "TOTAL" \
    "${total_cpu_requests}m" \
    "${total_cpu_limits}m" \
    "${total_memory_requests}Mi" \
    "${total_memory_limits}Mi"