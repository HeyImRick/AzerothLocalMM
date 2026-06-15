# AzerothLocalMM

Servidor local de World of Warcraft 3.3.5a baseado em AzerothCore e
mod-playerbots, com 100 bots, populacao regional e compilacao incremental.

## O que este repositorio fornece

- instalador para Linux da familia Fedora/Nobara;
- AzerothCore, mod-playerbots e mod-transmog fixados em revisoes conhecidas;
- patches das alteracoes locais;
- Docker Compose com banco, authserver e worldserver;
- build incremental persistente com CMake, Ninja e ccache;
- scripts para iniciar, validar e atualizar somente o worldserver.

O cliente do World of Warcraft, dados extraidos, bancos em execucao, senhas,
caches e binarios compilados nao fazem parte do repositorio.

## Requisitos

- Linux Fedora, Nobara ou derivado;
- Git;
- Docker Engine com o plugin Docker Compose;
- pelo menos 60 GB livres;
- cliente WoW 3.3.5a obtido legalmente pelo usuario.

## Instalacao

O guia detalhado, incluindo preparacao do Docker, autenticacao no repositorio
privado, cliente, conta, operacao e solucao de problemas, esta em:

**[docs/INSTALACAO-COMPLETA.md](docs/INSTALACAO-COMPLETA.md)**

Resumo para quem ja preparou Fedora/Nobara, Docker e acesso ao GitHub:

```bash
gh auth login --hostname github.com --git-protocol https --web
gh repo clone HeyImRick/AzerothLocalMM
cd AzerothLocalMM
chmod +x app/scripts/*.sh
./app/scripts/install-azeroth-local.sh
```

O instalador cria uma senha aleatoria para o banco em
`source/azerothcore/.env`, baixa as revisoes fixadas, aplica os patches e
compila o servidor. A primeira compilacao pode levar horas.

Depois, configure o cliente:

```text
set realmlist 127.0.0.1
```

O repositorio nao distribui o cliente nem arquivos proprietarios da Blizzard.

## Uso diario

Iniciar o servidor:

```bash
cd source/azerothcore
docker compose --project-name azeroth-local up -d
```

Parar sem apagar personagens ou bancos:

```bash
docker compose --project-name azeroth-local down
```

Nunca use `docker compose down -v`, pois isso pode remover o volume do banco.

## Build incremental

Depois da primeira base incremental:

```bash
./app/scripts/run-incremental-build.sh
./app/scripts/deploy-incremental-worldserver.sh
```

Somente os fontes alterados sao recompilados. Banco e authserver permanecem
ativos durante a troca do worldserver.

Mais detalhes: [docs/BUILD-INCREMENTAL.md](docs/BUILD-INCREMENTAL.md).

## Projetos upstream

- [AzerothCore Playerbots fork](https://github.com/mod-playerbots/azerothcore-wotlk)
- [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots)
- [mod-transmog](https://github.com/azerothcore/mod-transmog)
- instalador adaptado de [Dad's MMO Lab](https://github.com/DadsMmoLab/dads-mmo-lab)

Cada componente upstream permanece sujeito a sua propria licenca.
