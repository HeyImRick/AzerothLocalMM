# Selecao de fontes

Data da verificacao: 2026-06-11.

## Par fixado

### Core

- repositorio: `mod-playerbots/azerothcore-wotlk`;
- branch suportado: `Playerbot`;
- commit: `82d3bf237d5166934062ec8b6758fc65f1826c87`;
- data do commit: 2026-06-05;
- assunto: `Merge pull request #214 from mod-playerbots/test-staging`.

O commit possui `docker-compose.yml`, Dockerfiles e suporte explicito ao banco
`acore_playerbots`. Os jobs Linux observados no GitHub para GCC e Clang foram
concluidos com sucesso.

### Modulo Playerbots

- repositorio: `mod-playerbots/mod-playerbots`;
- branch suportado: `master`;
- commit: `7cd29783a158c9d2e8e180a81e2ca1cf0b7da9f8`;
- data do commit: 2026-06-06;
- assunto: `Fix errors with greater blessing system PR (#2439)`.

O README oficial exige o fork acima no branch `Playerbot`. O workflow oficial
do modulo faz checkout desse branch para os builds. Para o commit selecionado,
os jobs Linux Ubuntu 22.04/24.04 com GCC e Clang foram concluidos com sucesso.

## Revisao rejeitada

O commit posterior do modulo
`f989976c9392fe750a4e823341dd6bf7d0db1ae5` nao foi escolhido:

- os jobs Linux registrados foram cancelados;
- o job Windows falhou;
- o Quality Gate do SonarCloud falhou.

Isso nao prova que o commit esteja quebrado, mas nao fornece evidencia suficiente
para fixa-lo no MVP.

## Auction House Bot

Commit candidato:
`a680cc1c98290713e9b3d3289544af78e5186dc1`.

O fork do core inclui `mod-ah-bot` em sua matriz geral de modulos, e o README do
modulo declara compatibilidade com AzerothCore. Ainda assim, a combinacao exata
core + Playerbots + AH Bot sera validada separadamente antes da inclusao no build.

## Limites da evidencia

CI upstream reduz risco, mas nao substitui o build local. A compatibilidade final
sera aceita somente depois de:

- checkout dos commits exatos;
- validacao do Compose combinado;
- compilacao local;
- inicializacao dos bancos;
- teste funcional do worldserver e dos Playerbots.
