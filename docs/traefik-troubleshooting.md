# Traefik Troubleshooting

## Problembeschreibung

Traefik wird als Reverse Proxy im Nomad-Cluster eingesetzt, ist aber nicht über den Azure Load Balancer erreichbar.

## Bisherige Änderungen und Versuche

### 1. Ports geändert (9080/9081 → 8080/8081)

- **Problem**: Port-Konflikt mit anderen Diensten
- **Änderung**: Ports von 9080/9081 auf 8080/8081 geändert
- **Dateien**:
  - `jobs/traefik.nomad`
  - `terraform/modules/compute/main.tf`
  - `terraform/modules/network/main.tf`
- **Status**: Teilweise erfolgreich - Traefik läuft jetzt auf den Ports

### 2. Health Probes angepasst

- **Problem**: HTTP Health Probes schlagen fehl
- **Änderung**: Von HTTP auf TCP Health Probes umgestellt
- **Dateien**: `terraform/modules/compute/main.tf`
- **Status**: Teilweise erfolgreich - Health Probes sind konfiguriert

### 3. Traefik-Konfiguration umgestellt

- **Problem**: Traefik startet nicht korrekt
- **Änderung**: Von CLI-Argumenten auf TOML-Konfigurationsdatei umgestellt
- **Dateien**: `jobs/traefik.nomad`
- **Status**: Erfolgreich - Traefik startet und antwortet auf Ports

### 4. Consul-Integration

- **Problem**: Service-Discovery funktioniert nicht
- **Änderung**: Consul Catalog Provider aktiviert
- **Dateien**: `jobs/traefik.nomad`
- **Status**: Teilweise erfolgreich - Consul ist konfiguriert

### 5. Network Mode

- **Problem**: Container-Netzwerk isoliert
- **Änderung**: `network_mode = "host"` hinzugefügt
- **Dateien**: `jobs/traefik.nomad`
- **Status**: Erfolgreich - Traefik kann auf Ports zugreifen

### 6. Traefik-Version

- **Problem**: Möglicherweise Inkompatibilität mit neuester Version
- **Änderung**: Von v2.10 auf v2.2 downgrade
- **Dateien**: `jobs/traefik.nomad`
- **Status**: Erfolgreich - Traefik v2.2 läuft stabil

### 7. Web-App Traefik-Tags korrigiert

- **Problem**: Middleware-Referenz falsch (`@file` Suffix)
- **Änderung**: 
  - Entrypoint von `web` auf `http` geändert
  - Middleware-Definition direkt in Tags hinzugefügt
  - Middleware-Referenz korrigiert
- **Dateien**: `jobs/web.nomad`
- **Status**: Erfolgreich - Web-App ist jetzt über Traefik erreichbar

### 8. Load Balancer Backend Pool angepasst

- **Problem**: Load Balancer zeigt auf Server-VMs, aber Traefik läuft auf Client-VMs
- **Änderung**:
  - Neuen Backend Pool für Client-VMs erstellt
  - Load Balancer Regeln auf Client-VMs umgestellt
  - Client-VMs zum neuen Backend Pool hinzugefügt
- **Dateien**: `terraform/modules/compute/main.tf`
- **Status**: In Bearbeitung - Änderungen müssen noch angewendet werden

## Aktuelle Konfiguration

Die aktuelle Konfiguration basiert auf dem offiziellen HashiCorp-Tutorial:
https://developer.hashicorp.com/nomad/tutorials/load-balancing/load-balancing-traefik

- Traefik v2.2
- Host-Netzwerk-Modus
- TOML-Konfigurationsdatei
- Consul Catalog Provider
- Ports 8080 (HTTP) und 8081 (API/Dashboard)

## Aktueller Status

- **Traefik-Dienst**: Läuft auf Client-VM und antwortet auf Ports 8080 und 8081
- **Dashboard**: Erreichbar auf der Client-VM unter `localhost:8081`
- **Web-App Routing**: Funktioniert lokal, Web-App ist unter `localhost:8080/server-info` erreichbar
- **Externer Zugriff**: Noch nicht möglich über Load Balancer

## Nächste Schritte

1. **Überprüfe die Load Balancer Konfiguration**:
   - Backend Pool überprüfen (Server vs. Client VMs)
   - Health Probe Einstellungen validieren
   - Stelle sicher, dass der Load Balancer auf die Client-VMs zeigt

2. **Teste den externen Zugriff**:
   - `curl http://51.137.124.4/server-info`
   - Dies sollte funktionieren, wenn der Load Balancer korrekt konfiguriert ist

3. **Analysiere die Load Balancer Logs**:
   - Überprüfe, ob die Health Probes erfolgreich sind
   - Suche nach Fehlern in den Load Balancer Logs
