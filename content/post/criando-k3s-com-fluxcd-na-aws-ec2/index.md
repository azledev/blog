+++
date = '2026-03-23T08:48:22-03:00'
draft = false
title = 'Criando K3s com fluxcd na Aws'
comments = true
tags = ["k3s", "fluxcd", "git", "Github", "Kubernetes", "DevOps", "CI/CD"]
+++

Essa infraestrutura é muito robusta e prática, eu resolvi fazer na aws, mas por estar usando k3s, pode ser feito em qualquer servidor, e o processo de bootstrap
do fluxcd é o mesmo para o k3s não importa qual servidor se utilize.

## 1. Cofiguração da maquina da aws

Primeiro loguei na minha conta da aws, e cliquei em um novo ec2, selecionei amazon linux + t3.small e setei 30 gb de volume, que são todos permitidos
no plano gratuido da aws mensal. Depois liberei a porta 443 e 80 para web para quando eu subir as aplicações que vão rodar no k3s.

Acredito que com isso a parte da aws esta 100% feita. Depois para acessar por um dominio, eu configurei um dominio que eu tenho no cloucdflare para apontar 
para o ip publico da aws, como é só um caso de estudo, não vou comprar um ip publico, vou usar o que a aws deu de graça, que enquanto eu não reiniciar a maquina não deve mudar.

## 2. Instalando o k3s

```bash
# Dentro da EC2
curl -sfL https://get.k3s.io | sh -

# Verificar se subiu
sudo k3s kubectl get nodes

# Configurar acesso sem sudo
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
chmod 600 ~/.kube/config
```

### Acessar o cluster da sua máquina local

Caso a porta 6443 não fique aberta na maquina que conectada, que é o que eu queria, é possivel fazer uma ponte com a conexão ssh

```bash
# Cria um túnel: porta local 6444 → porta 6443 na EC2
ssh -i key.pem -N -L 6444:localhost:6443 ec2-user@xx.xxx.xxx.xx
```

1. Pegar o kubeconfig da EC2 sem sobrescrever o que ja possui

```bash
# Dentro do EC2 copie o config e cole no seu local com o nome config-ec2
cat ~/.kube/config
vim ~/.kube/config-ec2

# Ajusta o endereço para usar o túnel local (127.0.0.1:6444)
sed -i 's/127.0.0.1:6443/127.0.0.1:6444/g' ~/.kube/config-ec2
```

2. Eu tenho 2 configs no .kube, o meu raspberry e agora esse ec2, é possivel meclar e gerenciar por context

```bash
## Primeiro renomeio o contexto dos dois para conseguir se achar quando fazer a mesclagem
sed -i 's/: default/: rasp/g' ~/.kube/config-rasp
sed -i 's/: default/: ec2/g' ~/.kube/config-ec2

# A mesclagem dos dois arquivos
KUBECONFIG=~/.kube/config-rasp:~/.kube/config-ec2 kubectl config view --flatten > ~/.kube/config

# Verificar se deu certo
kubectl config get-contexts
```

Como usar:

```bash
# Listar contexts
kubectl config get-contexts

# Alternar entre clusters
kubectl config use-context rasp
kubectl config use-context ec2
```

Com isso o acesso do cluster deve estar funcional, mesmo que tenhamos multiplos cluster na máquina

## 3. Fazendo o bootstrap do fluxcd no cluster

Checar se o cluster atende os requisitos para configurar o fluxcd

```bash
flux check --pre
```

Fazer o bootstrap do fluxcd, adiconando componentes extras para automatizar as imagens. Ao rodar o bootstrap
será solicitado o token (PAT) do github. Eu normalmente dou acesso ao repo e workflows.

```bash
flux bootstrap github \
  --owner=USUARIO_GITHUB \
  --repository=REPOSITORY_GITHUB \
  --branch=REPOSITORY_BRANCH \
  --path=clusters/prd \
  --personal \
  --read-write-key \
  --components-extra=image-reflector-controller,image-automation-controller
```

Após isso o fluxcd vai criar a pasta cluster/prd/flux-system com o seu bootstrap e caso o repositório não exista ele vai criá-lo.
Com isso se tem funcionando o k3s em um ec2, espelhado num repositório do github com o fluxcd, e agora seria a etapa para subir as 
aplicações, que vai ficar para outro post.