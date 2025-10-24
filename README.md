# Gollum-SOP

Gollum-SOP is an opinionated setup of [Gollum](https://github.com/gollum/gollum) in order
to provide a lean and simple way of documenting [Standard Operating Procedures](https://en.wikipedia.org/wiki/Standard_operating_procedure) (SOPs).

Gollum-SOP bundles [gollum-auth](https://github.com/bjoernalbers/gollum-auth) with a custom
patch to make it working with Gollum version 6. Furthermore some custom additions are
added through `config.ru`.

## Installation

Best to use docker compose with the provided [docker-compose.yml](./docker-compose.yml) file.
Before using the file, the contents of the `SESSION_SECRET` variable needs to be set. `openssl`
can be used to generate such a string: `openssl rand -hex 32`.
Assuming your user is in the docker group:

```
$ sed -i "s|SESSION_SECRET=.*|SESSION_SECRET=$(openssl rand -hex 32)|" docker-compose.yml
$ docker-compose up -d
```
