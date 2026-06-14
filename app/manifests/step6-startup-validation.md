# Validacao da inicializacao da etapa 6

Data: 2026-06-12

Resultado:

- `client-data` v19 baixado, validado por SHA-256 e extraido;
- volume de dados com aproximadamente 3.1 GiB;
- MySQL 8.4.9 ativo e saudavel;
- bancos `acore_auth`, `acore_characters`, `acore_world` e
  `acore_playerbots` criados;
- importacao do core encerrada com codigo zero;
- 192 atualizacoes aplicadas durante a importacao inicial;
- `authserver` e `worldserver` ativos sem reinicios inesperados;
- Playerbots carregado e thread de mundo inicializada;
- limites `MinRandomBots=100` e `MaxRandomBots=100` aplicados por variaveis de
  ambiente;
- 32 bots foram observados online na primeira inicializacao;
- realm `AzerothCore` configurado em `127.0.0.1:8085`;
- authserver publicado apenas em `127.0.0.1:3724`;
- worldserver publicado apenas em `127.0.0.1:8085`;
- banco de dados sem porta publicada no host.
- filtro DBC de nomes reservados desativado para permitir nomes locais sem
  relaciona-los ao nome da conta; unicidade e demais validacoes permanecem;

Automacao:

- `app/scripts/preflight-step6-startup.sh`;
- `app/scripts/run-step6-startup-worker.sh`;
- `app/scripts/start-step6-startup.sh`;
- `app/scripts/status-step6-startup.sh`.

O worker garante a criacao de `env/dist/etc/modules/playerbots.conf` a partir
do arquivo `.dist` antes de iniciar os servidores.

Proxima etapa:

- criar uma conta administrativa local;
- configurar o cliente WoW para o realm local;
- testar login, criacao de personagem e entrada no mundo.
