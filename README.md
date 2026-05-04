# 🚀 Nexus Core - Personal Home Lab

Este repositorio contiene la configuración y automatización de mi infraestructura personal de servicios, diseñada bajo principios de **Infrastructure as Code (IaC)** y **arquitectura de microservicios**.

## 🛠️ Arquitectura del Sistema
El laboratorio corre sobre una máquina virtual con **Ubuntu Server**, gestionando los servicios mediante **Docker** y orquestando la configuración con **Ansible**.



### 🌐 Servicios Web (Docker Compose)
Utilizo un modelo de **Reverse Proxy** para centralizar el tráfico:
* **Gateway (Nginx):** Actúa como punto de entrada (puerto 80), gestionando el tráfico hacia los servicios internos.
* **Web-Core:** Servidor de aplicaciones Nginx que sirve el portal principal.
* **Dozzle:** Interfaz de observabilidad para monitorización de logs en tiempo real (puerto 8080).

### 🤖 Automatización y Hardening (Ansible)
La gestión de la máquina base está automatizada para garantizar un entorno seguro y reproducible:
* **Gestión de Identidades:** Creación automatizada de usuarios (`admin`, `auditor`) con permisos granulares.
* **SSH Hardening:** Desactivación del login de root y configuración de seguridad para accesos remotos.
* **Idempotencia:** Todos los playbooks están diseñados para poder ejecutarse múltiples veces sin alterar el estado deseado.

## 📁 Estructura del Proyecto
```text
.
├── ansible/
│   └── manage_users.yml      # Playbook de gestión de usuarios y seguridad
├── nginx/
│   └── default.conf          # Configuración del servidor Proxy
├── web/
│   └── index.html            # Código fuente del portal principal
├── docker-compose.yml        # Orquestación de contenedores
└── README.md                 # Documentación del proyecto

## 🚀 Cómo desplegar el entorno

Para poner en marcha este laboratorio, asegúrate de tener instalados **Docker** y **Ansible** en tu máquina. Sigue estos pasos:

### 1. Configuración del sistema (Hardening y Usuarios)
Ejecuta el playbook para asegurar el servidor y crear los usuarios autorizados:
```bash
ansible-playbook ansible/playbooks/manage_users.yml -c local -i localhost, -K
