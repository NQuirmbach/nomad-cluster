# Azure Bastion für Nomad Cluster

Der Azure Bastion Service bietet sicheren SSH-Zugriff auf die Nomad Clients und Server im Cluster direkt aus dem Azure Portal. Im Gegensatz zu einem selbst verwalteten Bastion Host bietet Azure Bastion mehrere Vorteile in Bezug auf Sicherheit, Verwaltung und Benutzerfreundlichkeit.

## Architektur

```
Azure Portal --> Azure Bastion Service --> Nomad Servers/Clients (Private IPs)
```

- Azure Bastion befindet sich in einem dedizierten Subnetz (`AzureBastionSubnet` mit CIDR `10.0.20.0/27`)
- Die Nomad Server und Clients befinden sich im Cluster-Subnetz (`10.0.10.0/24`)
- Die NSGs der VMs erlauben SSH-Zugriff nur aus dem Azure Bastion Subnetz

## Vorteile von Azure Bastion

1. **Erhöhte Sicherheit**
   - Keine öffentlichen IPs für VMs erforderlich
   - Integrierte Schutzmaßnahmen gegen Brute-Force-Angriffe
   - TLS-gesicherte Verbindungen

2. **Einfache Verwaltung**
   - Keine Verwaltung einer eigenen Bastion VM (Patches, Updates, etc.)
   - Keine SSH-Schlüssel-Verwaltung auf Client-Seite
   - Integrierte Protokollierung und Überwachung

3. **Benutzerfreundlichkeit**
   - Zugriff direkt aus dem Azure Portal im Browser
   - Unterstützung für SSH und RDP
   - Keine Client-Software oder Agenten erforderlich

## Verbindung zu VMs über Azure Bastion

### Über das Azure Portal

1. Navigiere zum Azure Portal
2. Gehe zu "Virtual Machines" oder "Virtual Machine Scale Sets"
3. Wähle die gewünschte VM aus
4. Klicke auf "Connect" und wähle "Bastion"
5. Gib den Benutzernamen (`azureuser`) und das Passwort oder den SSH-Schlüssel ein
6. Klicke auf "Connect"

### Über die Azure CLI

```bash
# Verbindung zu einer VM über Azure Bastion
az network bastion ssh \
  --name <prefix>-bastion \
  --resource-group <resource-group-name> \
  --target-resource-id <vm-resource-id> \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa
```

## Sicherheitshinweise

- Azure Bastion bietet eine sichere Verbindung zu VMs ohne öffentliche IP-Adressen
- Alle Verbindungen werden protokolliert und können überwacht werden
- Die NSGs der VMs erlauben SSH-Zugriff nur aus dem Azure Bastion Subnetz
- Azure Bastion unterstützt Azure RBAC für die Zugriffskontrolle

## Kosten

Azure Bastion wird als verwalteter Dienst abgerechnet. Die Kosten setzen sich zusammen aus:

1. Stündliche Gebühr für den Azure Bastion Service
2. Ausgehender Datenverkehr
3. Öffentliche IP-Adresse für Azure Bastion

Weitere Informationen zu den Kosten finden Sie in der [Azure-Preisübersicht](https://azure.microsoft.com/de-de/pricing/details/azure-bastion/).
