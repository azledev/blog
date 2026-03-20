+++
date = '2026-03-20T06:06:26-03:00'
draft = true
title = 'Criação de CI/CD Com Github E DockerHub'
comments = true
tags = ["Docker", "Dockerhub", "git", "Github", "Build", "DevOps", "CI/CD"]
+++

Finalmente vamos fazer um pouco de tecnologias, recentemente preciso fazer um ‘freela‘ que consiste em fazer o ‘build‘ de uma aplicação em ‘Play Framework’ e 
enviar para o Dockerhub privado. Para convencia e manter sigilo do cliente, vou manter o nome da aplicação para "app-api".

Primeira coisa que fiz foi receber acesso ao repositório no github, esse projeto tem umas dependencias meio problematicas no quesito dificil de baixar, mas todas públicas, 
então fiz uma imagem de build só para ele e mandei para o dockerhub com o nome app-api-builder.

Próxima etapa foi fazer o Dockerfile que utilize esse app-api-builder para compilar e gerar a imagem final, essa aplicação precisa fazer build de angular e play 
framework que utiliza java na build, sendo que o próprio play vai servir a parte do angular, então primeiro temos que fazer a build do frontend e depois a
build do backend, no final o dockerfile ficou assim.

```Dockerfile

```


Depois disso foi necessário configurar variáveis de ambiente secret no repositório para enviar a imagem final ao DockerHub e o github actions, criando um arquivo deploy.yml 
no seguinte caminho do repositório ".github/workflows/deploy.yml"

```yaml

```

Eu sei que é fácil fazer um git tag vX.Y.Z, git push origin vX.Y.Z, mas vou deixar helper para garantir que quando forem fazer uma build por tag, o desenvolvedor não
possa enviar com a tag errada, publish.sh.

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

Beleza, com isso já temos um fluxo de, ao gerar uma tag no formato correto na branch master, seja acionado o evento de deploy da aplicação,
e com isso terminamos essa a criação do CI/CD Com Github E DockerHub