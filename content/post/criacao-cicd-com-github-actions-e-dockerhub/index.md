+++
date = '2026-03-21T06:06:26-03:00'
draft = false
title = 'Criação de CI/CD Com Github Actions e DockerHub'
comments = true
tags = ["Docker", "Dockerhub", "git", "Github", "Build", "DevOps", "CI/CD"]
+++

Finalmente vamos falar um pouco de tecnologias, recentemente precisei fazer um ‘freela‘ que consiste em ‘build‘ de uma aplicação ‘Play Framework’ e 
enviar para o repositório do Dockerhub privado. Para conveniência e manter sigilo, o nome da aplicação é "app-api".

Primeira coisa que fiz foi receber acesso ao repositório no github, esse projeto tem umas dependencias do java meio problematicas no quesito dificil de baixar, mas todas 
públicas, então fiz uma imagem de build só para ele e mandei para o dockerhub com o nome app-api-builder.

Próxima etapa foi fazer o Dockerfile que utilize esse app-api-builder para compilar e gerar a imagem final, essa aplicação precisa fazer build de angular e play 
framework que utiliza java na build, sendo que o próprio play vai servir a parte do angular, então primeiro temos que fazer a build do frontend e depois a
build do backend, e no final pegamos os binarios da aplicação em play e mandamos para uma imagem de java sem as bibliotecas extras para rodar a aplicação limpa, 
no final o dockerfile ficou assim.

```Dockerfile
FROM empresaX/app-api-builder AS builder

WORKDIR /build

COPY  . .

# Build frontend
RUN cd frontend && \
    npm ci && \
    npm run build

# Copiando dist do frontend para o play framework servir
RUN mkdir -p public && \
    mv frontend/dist/browser/* public/

# Build backend
RUN sbt clean compile stage

# imagem final
FROM eclipse-temurin:8-jdk

WORKDIR /data

COPY --from=builder /build/infra/data /data

EXPOSE 9000

CMD ["/data/app/bin/app-api","-Dconfig.resource=application.prod.conf", "-DapplyEvolutions.default=true","-DapplyDownEvolutions.default=true", "-Dfile.encoding=UTF-8", "-Dhttp.port=9000", "-Dresourcedir=/data/resources"]
```

Com a imagem criada, chegou a hora de testar se esta funcionando rodando localmente com "docker run". Acabou que deu quase 100% certo, quando tentava acessar a página servida pelo play, estava
recebendo erros de mimes vazios "was blocked because of a disallowed MIME type (“”)". Então tive que fazer um ajuste na rota que carrega os files servidos no 
play. Não vou postar a correção que fiz aqui, vou só relatar mesmo.

Depois disso foi necessário configurar variáveis de ambiente secret no repositório para enviar a imagem final ao DockerHub pelo github actions, criando um arquivo docker-build.yml sendo
para que o trigger somente ocorra quando mande uma tag que começa v, referente a versão.

Os steps do action ficaram assim:

 - recebe a tag vX.Y.Z
 - checkout do repositório para o commit da tag
 - login do dockerhub com usuario do secrets
 - pega tag do evento de push
 - constroi a imagem e envia para o repositório privado

Eu criei o workflow no seguinte caminho ".github/workflows/docker-build.yml" e ficou assim:

```yaml
name: Build and Push Docker Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract tag name
        id: extract_tag
        run: echo "TAG=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: infra/Dockerfile
          push: true
          platforms: linux/amd64
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/app-api:latest
            ${{ secrets.DOCKER_USERNAME }}/app-api:${{ steps.extract_tag.outputs.TAG }}
```

Eu sei que é fácil fazer um git tag vX.Y.Z, git push origin vX.Y.Z, mas vou deixar helper para garantir que quando forem fazer uma build por tag, seja validado o padrão e o desenvolvedor não
possa enviar com a tag errada, segue script publish.sh.

```shell
#!/bin/bash

VERSION="$1"

if [[ -z "$VERSION" ]]; then
  echo "Uso: $0 vX.Y.Z"
  exit 1
fi

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Versão inválida! Use o formato vX.Y.Z (ex: v1.2.3)"
  exit 1
fi

git tag "$VERSION"
if [[ $? -ne 0 ]]; then
  echo "Erro ao criar a tag $VERSION"
  exit 1
fi


git push origin "$VERSION"
if [[ $? -ne 0 ]]; then
  echo "Erro ao enviar a tag $VERSION para o origin"
  exit 1
fi

echo "Tag $VERSION criada e enviada com sucesso!"
```

Beleza, com isso já temos um fluxo de, podemos rodar "./publish.sh v0.0.1" na branch master e vai gerar uma tag no formato que o workflow espera, 
acionado o evento de docker-build da aplicação, e com isso está pronta a criação do CI/CD Com Github Actions E DockerHub