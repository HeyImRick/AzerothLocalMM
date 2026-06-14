# Instalacao completa do AzerothLocalMM

Este guia permite instalar e usar o servidor sem depender de orientacao do
autor. Leia tudo uma vez antes de iniciar.

## 1. O que sera instalado

O projeto prepara localmente:

- AzerothCore WotLK;
- mod-playerbots com 100 bots;
- banco MySQL em Docker;
- authserver e worldserver;
- populacao regional de bots;
- ambiente de compilacao incremental.

O repositorio nao inclui o cliente World of Warcraft 3.3.5a. O usuario deve
possuir sua propria copia legal do cliente.

## 2. Sistema suportado

O instalador foi preparado e testado para:

- Nobara Linux;
- Fedora Linux;
- distribuicoes diretamente derivadas da familia Fedora/RHEL.

Requisitos:

- processador x86-64;
- 16 GB de RAM recomendados;
- pelo menos 60 GB livres para a instalacao inicial;
- internet estavel;
- Git, OpenSSL, Docker Engine e Docker Compose;
- acesso autorizado ao repositorio privado.

A primeira compilacao pode levar de 1 a 4 horas, dependendo do processador.

## 3. Preparar Fedora ou Nobara

Abra um terminal e instale as ferramentas:

```bash
sudo dnf install -y git gh openssl moby-engine docker-compose
```

Ative o Docker:

```bash
sudo systemctl enable --now docker
```

Adicione seu usuario ao grupo `docker`:

```bash
sudo usermod -aG docker "$USER"
```

Reinicie a sessao. A forma mais simples e reiniciar o computador:

```bash
systemctl reboot
```

Depois de entrar novamente, confirme:

```bash
docker info
docker compose version
```

Os dois comandos devem terminar sem erro e sem `sudo`.

## 4. Autenticar no GitHub

Como o repositorio e privado, autentique a GitHub CLI:

```bash
gh auth login --hostname github.com --git-protocol https --web
```

Escolha a autenticacao pelo navegador e autorize a conta que recebeu acesso ao
repositorio.

Confirme:

```bash
gh auth status
```

## 5. Baixar o projeto

Escolha uma pasta com pelo menos 60 GB livres. Evite discos formatados em NTFS
para o build do servidor.

```bash
cd "$HOME"
gh repo clone HeyImRick/AzerothLocalMM
cd AzerothLocalMM
chmod +x app/scripts/*.sh
```

Os comandos deste guia assumem que o clone foi criado em
`$HOME/AzerothLocalMM`. Se escolher outro local, substitua esse caminho nos
exemplos.

Para confirmar que esta no lugar correto:

```bash
test -f README.md && test -x app/scripts/install-azeroth-local.sh
```

## 6. Executar a instalacao

Execute:

```bash
./app/scripts/install-azeroth-local.sh
```

O instalador:

1. verifica Linux, Docker, internet e espaco;
2. baixa as revisoes fixadas do AzerothCore e mod-playerbots;
3. aplica as alteracoes deste projeto;
4. gera uma senha aleatoria para o banco;
5. compila as imagens Docker;
6. inicializa banco, authserver e worldserver;
7. espera o servidor ficar pronto;
8. orienta a criacao da conta.

Nao feche o terminal durante a primeira compilacao. O computador pode ficar
ocupado por algumas horas.

O log de build fica em:

```text
data/logs/playerbots-build.log
```

## 7. Criar a conta do jogo

Quando o instalador solicitar, abra outro terminal:

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
docker compose --project-name azeroth-local attach ac-worldserver
```

No console `AC>`, crie a conta:

```text
account create SEU_USUARIO SUA_SENHA
account set gmlevel SEU_USUARIO 3 -1
```

Use um nome de conta simples, sem espacos. Para sair do console sem desligar o
servidor, pressione:

```text
Ctrl+P, depois Ctrl+Q
```

Nao pressione `Ctrl+C` dentro do console anexado.

## 8. Preparar o cliente WoW 3.3.5a

Crie a pasta esperada:

```bash
mkdir -p "$HOME/AzerothLocalMM/client/WoW-3.3.5a"
```

Coloque sua copia do cliente dentro dela. O executavel deve existir em:

```text
AzerothLocalMM/client/WoW-3.3.5a/Wow.exe
```

Localize o arquivo `realmlist.wtf`:

```bash
find "$HOME/AzerothLocalMM/client/WoW-3.3.5a" \
  -iname realmlist.wtf -print
```

Ele normalmente fica na raiz do cliente ou em `Data/enUS`, `Data/enGB` ou
outra pasta de idioma. Deixe seu conteudo assim:

```text
set realmlist 127.0.0.1
```

Nao execute `Launcher.exe`, pois ele pode alterar o cliente. Use `Wow.exe`.

## 9. Instalar Wine e abrir o jogo

No Fedora ou Nobara:

```bash
sudo dnf install -y wine wmctrl libnotify
```

Com o servidor ativo, abra o cliente:

```bash
cd "$HOME/AzerothLocalMM"
./app/scripts/launch-wow-client.sh
```

Se o cliente estiver em outra pasta:

```bash
WOW_CLIENT_DIR="/caminho/para/WoW-3.3.5a" \
  ./app/scripts/launch-wow-client.sh
```

Se quiser usar um executavel Wine especifico:

```bash
WINE_BIN="/caminho/para/wine" \
  ./app/scripts/launch-wow-client.sh
```

Entre usando a conta criada no console do worldserver.

## 10. Iniciar e parar depois da instalacao

Entre na pasta do servidor:

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
```

Iniciar:

```bash
docker compose --project-name azeroth-local up -d
```

Ver estado:

```bash
docker compose --project-name azeroth-local ps
```

Ver logs do mundo:

```bash
docker compose --project-name azeroth-local logs -f ac-worldserver
```

Sair dos logs com `Ctrl+C` e seguro. Isso nao encerra o container.

Parar:

```bash
docker compose --project-name azeroth-local down
```

Esse comando para os containers, mas preserva personagens, contas e bancos.
Nao use `down -v`, pois a opcao `-v` remove volumes e pode apagar o banco.

## 11. Confirmar os bots

No log do worldserver, procure:

```text
mod-playerbots initialized
100/100 Bot ... logged in
```

Dentro do jogo, a populacao regional usa o personagem GM ativo como referencia.
Por padrao:

- 20% dos bots ficam na zona do GM;
- 30% ficam em zonas proximas;
- 50% permanecem distribuidos pelo mundo.

Comandos e exemplos administrativos estao em
[GUIA-COMANDOS-GM.md](../GUIA-COMANDOS-GM.md).

## 12. Atualizar o repositorio

Pare o servidor e atualize:

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
docker compose --project-name azeroth-local down
cd "$HOME/AzerothLocalMM"
git pull --ff-only
```

Leia o historico recente:

```bash
git log --oneline -10
```

Nao execute novamente o instalador sem ler as notas da atualizacao. Uma versao
futura pode trazer passos adicionais.

## 13. Compilacao incremental

Esta secao e necessaria somente para quem modificar codigo C++ ou receber uma
atualizacao de fontes.

```bash
cd "$HOME/AzerothLocalMM"
./app/scripts/preflight-incremental-build.sh
./app/scripts/run-incremental-build.sh
./app/scripts/deploy-incremental-worldserver.sh
```

A primeira base incremental e demorada. Depois dela, somente arquivos alterados
sao recompilados.

Alteracoes apenas em:

```text
source/azerothcore/env/dist/etc/modules/playerbots.conf
```

nao exigem compilacao. Recrie apenas o worldserver:

```bash
./app/scripts/deploy-incremental-worldserver.sh
```

## 14. Solucao de problemas

### Docker exige permissao

Se `docker info` mostrar `permission denied`:

```bash
sudo usermod -aG docker "$USER"
systemctl reboot
```

### Servidor nao aparece como ativo

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
docker compose --project-name azeroth-local ps
docker compose --project-name azeroth-local logs --tail 200 ac-worldserver
docker compose --project-name azeroth-local logs --tail 200 ac-authserver
docker compose --project-name azeroth-local logs --tail 200 ac-database
```

### Porta ocupada

O servidor usa:

- `3724` para autenticacao;
- `8085` para o mundo.

Verifique:

```bash
ss -ltnp | grep -E ':(3724|8085)\b'
```

### Cliente nao conecta

Confirme:

```bash
docker ps
cat /caminho/para/realmlist.wtf
```

O `realmlist.wtf` deve apontar para `127.0.0.1`, e os containers de banco,
authserver e worldserver devem estar ativos.

### Compilacao interrompida

Verifique o final do log:

```bash
tail -n 200 "$HOME/AzerothLocalMM/data/logs/playerbots-build.log"
```

Corrija a causa e execute o instalador novamente. Ele preserva checkouts e
imagens ja existentes quando possivel.

### Falta de espaco

```bash
df -h "$HOME/AzerothLocalMM"
docker system df
```

Nao apague `source`, `var`, volumes Docker ou `.env` sem ter backup e entender
o impacto.

## 15. Arquivos importantes

- `source/azerothcore/.env`: senha local e parametros; nao compartilhar;
- `source/azerothcore/env/dist/etc`: configuracoes do servidor;
- `source/azerothcore/env/dist/logs`: logs do AzerothCore;
- `data/logs`: logs dos instaladores;
- `var/build`: build incremental;
- `var/ccache`: cache de compilacao;
- `var/dist/bin/worldserver`: worldserver incremental;
- `client/WoW-3.3.5a`: cliente particular do usuario.

## 16. Backup

O banco precisa estar ativo durante o dump. Inicie os containers, se necessario:

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
docker compose --project-name azeroth-local up -d
```

Crie um dump dos quatro bancos:

```bash
mkdir -p "$HOME/AzerothLocalMM/backups"
docker exec azeroth-local-database sh -lc \
  'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction \
  --routines --events --databases acore_auth acore_characters \
  acore_world acore_playerbots' \
  > "$HOME/AzerothLocalMM/backups/azeroth-databases.sql"
```

Depois do dump, pare o servidor:

```bash
cd "$HOME/AzerothLocalMM/source/azerothcore"
docker compose --project-name azeroth-local down
```

Compacte o dump, o `.env` e as configuracoes:

```bash
tar -czf "$HOME/AzerothLocalMM-backup.tar.gz" \
  -C "$HOME/AzerothLocalMM" \
  backups source/azerothcore/.env source/azerothcore/env/dist/etc
```

Guarde esse arquivo fora da pasta do projeto. Ele contem senha e dados de
personagens. Nunca publique backups, `.env`, cliente ou dados do jogo no
GitHub.
