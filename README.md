# Linux Desktop XFCE4 XRDP

![GitHub action workflow status](https://github.com/AgorastisMesaio/docker-img-linuxrdp/actions/workflows/docker-publish.yml/badge.svg)

This repository contains a `Dockerfile` aimed to create a *base image* to provide a Linux Desktop with XFCE4 and XRDP.

Typical use cases:

- Setup a cloud desktop accessible through Guacamole
- Setup multiple remote desktop accessible through RDP clients.
- Demo and test VDI replacement use cases

## Consume in your `docker-compose.yml`

This is an example use case; I want to have a remote desktop accessible through a guacamole service:

```yaml
### Docker Compose example

volumes:
  # Guacamole
  gc_backend_drive:
    driver: local
  gc_backend_record:
    driver: local
  gc_postgres_data:
    driver: local
  gc_frontend_drive:
    driver: local
  gc_frontend_record:
    driver: local

networks:
  my_network:
    name: my_network
    driver: bridge

services:
  ct_linuxrdp:
    image: agorastismesaio/docker-img-linuxrdp
    hostname: linuxrdp.company.com
    container_name: ct_linuxrdp
    ports:
      - "9022:22"     # Exposed ssh port
      - "9002:9001"   # Exposed supervisord port
      - "33892:3389"  # Exposed RDP port
    environment:
      - ROOTPASS=alpine           # Optional
      - USERNAME=alpine           # Optional
      - USERPASS=alpine           # Optional
    volumes:
      - ./config:/config          # Optional
    networks:
      - my_network

  #
  # I've included Guacamole example below. It's not part of this repository,
  # and it's only for your information as an example.
  #
  gc_guacd:
    image: guacamole/guacd
    container_name: gc_guacd
    restart: always
    volumes:
      - gc_backend_drive:/drive
      - gc_backend_record:/var/lib/guacamole/recordings
    networks:
      - my_network

  gc_frontend:
    image: guacamole/guacamole
    hostname: guacamole.company.com
    container_name: gc_frontend
    restart: always
    environment:
      GUACD_HOSTNAME: gc_guacd
      POSTGRES_DATABASE: guacamole_db
      POSTGRES_HOSTNAME: gc_postgres
      POSTGRES_PASSWORD: 'ChooseYourOwnPasswordHere1234'
      POSTGRES_USER: guacamole_user
    links:
    - gc_guacd
    volumes:
      - gc_frontend_drive:/drive
      - gc_frontend_record:/var/lib/guacamole/recordings
    ports:
      - 8080:8080
    networks:
      - my_network
    depends_on:
    - gc_guacd
    - gc_postgres

  gc_postgres:
    image: postgres:15.2-alpine
    hostname: gc_postgres.company.com
    container_name: gc_postgres
    restart: always
    environment:
      - PGDATA=/var/lib/postgresql/data/guacamole
      - POSTGRES_DB=guacamole_db
      - POSTGRES_USER=guacamole_user
      - POSTGRES_PASSWORD='ChooseYourOwnPasswordHere1234'
    networks:
      - my_network
    volumes:
    - ./init:/docker-entrypoint-initdb.d:ro
    - sw_gc_postgres_data:/var/lib/postgresql/data
```

I've left ./config directory available to be able to share files with the container.

```zsh
.
├── config
│   ├── run.sh
```

- `run.sh` It's optional. I've included a sample script. If this script is present it'll be called/executed from within `entrypoint.sh`

Start your services

```sh
docker compose up --build -d
```

In the example above you would have the following ports available from this base image. Not that I'm not covering the guacamole ones

- `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 9022 alpine@localhost`
- [http://localhost:9002](http://localhost:9002) - Exposed supervisord port
- [http://localhost:33892](http://localhost:33892) - Exposed RDP port, that you can consume from any RDP client.

Otherwise, connect to the container directly

```zsh
docker exec -it ct_linuxrdp /bin/bash
```

## For developers

If you copy or fork this project to create your own base image.

### Building the Image

To build the Docker image, run the following command in the directory containing the Dockerfile:

```sh
docker build -t your-image/docker-img-linuxrdp .
or
docker compose up --build -d
```

### Troubleshoot

```sh
docker run --rm --name ct_linuxrdp --hostname linuxrdp --shm-size 1g -p 33892:3389 -p 9022:22 -p 5992:5900 agorastismesaio/docker-img-linuxrdp
```
