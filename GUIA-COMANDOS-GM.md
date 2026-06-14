# Guia de comandos GM e Playerbots

Este guia corresponde ao AzerothCore Playerbot instalado neste projeto:

- core: `82d3bf237d5166934062ec8b6758fc65f1826c87`;
- mod-playerbots: `7cd29783a158c9d2e8e180a81e2ca1cf0b7da9f8`;
- conta administrativa configurada com nivel GM 3.

Os comandos abaixo devem ser digitados no chat do jogo, normalmente com `Enter`.
Comandos administrativos comecam com ponto (`.`). Comandos enviados diretamente
a um bot sao escritos em sussurro para o bot e normalmente nao usam ponto.

## 1. Ajuda dentro do jogo

```text
.commands
```

Lista os comandos permitidos para o nivel da conta.

```text
.help
.help gm
.help modify speed
.help character rename
```

Mostra a sintaxe oficial de um comando. Use `.help` sempre que um exemplo deste
guia nao aceitar os argumentos esperados.

## 2. Alvos e argumentos

Muitos comandos atuam:

1. no personagem, NPC ou objeto selecionado;
2. no proprio GM quando nao existe alvo;
3. no personagem informado pelo nome.

Clique no retrato ou no personagem antes de executar comandos que alteram alvo.

Convencoes usadas neste guia:

- `<nome>`: valor obrigatorio;
- `[nome]`: valor opcional;
- `<ID>`: identificador numerico;
- `on/off`: ativar ou desativar;
- nomes com espacos geralmente precisam de aspas.

Para descobrir IDs:

```text
.lookup item espada
.lookup spell teleport
.lookup quest defias
.lookup creature gryphon
.lookup gobject chest
.lookup faction stormwind
.lookup teleport dalaran
```

## 3. Modo GM

Ativar e desativar o modo GM:

```text
.gm on
.gm off
.gm
```

`.gm` sem argumento mostra o estado atual.

Comandos relacionados:

```text
.gm chat on
.gm chat off
.gm visible on
.gm visible off
.gm fly on
.gm fly off
.gm ingame
.gm list
```

- `.gm chat on`: mostra o distintivo GM no chat.
- `.gm visible off`: esconde o GM dos jogadores comuns.
- `.gm fly on`: permite voo; use junto de `.modify speed fly`.
- `.gm list`: lista contas GM e seus niveis.

## 4. Teleporte e posicao

Teleportar para locais cadastrados:

```text
.tele stormwind
.tele orgrimmar
.tele dalaran
.tele ironforge
```

Pesquisar nomes de teleporte:

```text
.lookup teleport dalaran
.lookup teleport storm
```

Voltar ao ponto anterior:

```text
.recall
```

Ir ate outro personagem ou traze-lo:

```text
.appear <personagem>
.summon <personagem>
```

Ver coordenadas:

```text
.gps
```

Ir para coordenadas:

```text
.go xyz <x> <y> [z] [mapa] [orientacao]
```

Outros destinos:

```text
.go creature id <entry>
.go creature name <nome>
.go gameobject id <entry>
.go graveyard <ID>
.go taxinode <ID>
.go trigger <ID>
.go quest starter <questID>
.go quest ender <questID>
```

## 5. Nivel, atributos e movimento

Subir ou reduzir niveis:

```text
.levelup
.levelup 10
.levelup -5
.levelup <personagem> 10
```

Definir nivel diretamente:

```text
.character level [personagem] <nivel>
```

Velocidade:

```text
.modify speed all 3
.modify speed fly 3
.modify speed swim 2
.modify speed walk 2
.modify speed backwalk 2
```

O valor `1` e a velocidade normal. Valores muito altos podem causar problemas
de movimento ou desconexao.

Vida e recursos:

```text
.modify hp <valor>
.modify mana <valor>
.modify energy <valor>
.modify rage <valor>
.modify runicpower <valor>
```

Outras alteracoes:

```text
.modify scale 1.5
.modify gender male
.modify gender female
.modify talentpoints 20
.modify drunk 0
```

Dinheiro:

```text
.modify money <cobre>
```

O valor usa cobre:

- `100` = 1 prata;
- `10000` = 1 ouro;
- `1000000` = 100 ouros;
- valores negativos removem dinheiro.

Exemplo:

```text
.modify money 1000000
```

## 6. Invulnerabilidade e cheats

```text
.cheat god on
.cheat god off
.cheat cooldown on
.cheat casttime on
.cheat power on
.cheat waterwalk on
.cheat taxi on
.cheat explore 1
.cheat status
```

- `god`: impede morte/dano normal.
- `cooldown`: remove tempos de recarga.
- `casttime`: remove tempo de lancamento.
- `power`: remove custo de mana, energia ou raiva.
- `taxi`: libera temporariamente todas as rotas.
- `explore 1`: revela o mapa; `explore 0` oculta novamente.

## 7. Vida, morte e salvamento

```text
.die
.revive
.revive <personagem>
.save
.cooldown
.cooldown <spellID>
```

- `.die`: mata o alvo ou o proprio GM.
- `.revive`: ressuscita o jogador selecionado; sem alvo, tenta ressuscitar o proprio GM.
- `.revive <personagem>`: forma mais confiavel, pois identifica explicitamente quem sera ressuscitado.
- `.save`: salva imediatamente o personagem.
- `.cooldown`: remove todas as recargas.

Se o personagem morto nao conseguir executar o comando pelo chat, use o console do
`worldserver` sem o ponto:

```text
revive NomeDoPersonagem
```

Para personagem offline, o servidor agenda a ressurreicao para o proximo login.

### Peak de classe

```text
.peak <classe>
```

Exemplos:

```text
.peak guerreiro
.peak mago
.peak cavaleiro-da-morte
```

Classes aceitas: `guerreiro`, `paladino`, `cacador`, `ladino`, `sacerdote`,
`cavaleiro-da-morte`, `xama`, `mago`, `bruxo` e `druida`. Os nomes em ingles
tambem sao aceitos.

O comando exige que a classe informada corresponda a classe real do personagem.
Ele eleva ao nivel maximo, aprende magias, talentos, profissoes, receitas e
idiomas, maximiza habilidades e aplica o melhor perfil BiS disponivel para a
especializacao detectada. Tambem define o dinheiro no limite suportado pelo
servidor: `214748 ouro, 36 prata e 46 cobre`.

Atencao: `.peak` destroi os itens equipados e todos os itens equipaveis presentes
nas bolsas antes de gerar o novo conjunto.

## 8. Itens e inventario

Pesquisar item:

```text
.lookup item <parte do nome>
```

Adicionar item:

```text
.additem <itemID>
.additem <itemID> <quantidade>
.additem <personagem> <itemID> <quantidade>
```

Remover item usando quantidade negativa:

```text
.additem <itemID> -1
```

Adicionar conjunto:

```text
.additem set <itemsetID>
```

Consultar inventario:

```text
.character check bag
.character check bank
.character check profession
```

Enviar por correio:

```text
.send items <personagem> "Assunto" "Mensagem" <itemID>:<quantidade>
.send money <personagem> "Assunto" "Mensagem" <cobre>
```

O correio aceita ate 12 pilhas de itens por mensagem.

## 9. Magias, habilidades e auras

Pesquisar magia:

```text
.lookup spell <nome>
.lookup spell id <spellID>
```

Aprender e desaprender:

```text
.learn <spellID>
.learn <spellID> all
.unlearn <spellID>
.unlearn <spellID> all
```

Pacotes de aprendizado:

```text
.learn all my class
.learn all my trainer
.learn all my talents
.learn all my quest
.learn all gm
.learn all lang
.learn all recipes enchanting
.learn all crafts
```

Habilidades:

```text
.maxskill
.setskill <skillID> <nivel> [maximo]
```

Lancar magia e manipular aura:

```text
.cast <spellID>
.cast <spellID> triggered
.aura <spellID>
.unaura <spellID>
```

## 10. Profissoes

Profissoes envolvem tres partes diferentes:

1. possuir a habilidade da profissao;
2. definir o nivel atual/maximo da habilidade;
3. aprender as receitas ou tecnicas.

### Consultar profissoes

No proprio personagem:

```text
.character check profession
```

Em outro personagem, selecione-o antes ou informe o nome:

```text
.character check profession <personagem>
```

Pesquisar o ID de uma habilidade:

```text
.lookup skill alchemy
.lookup skill mining
.lookup skill tailoring
```

### Aprender uma profissao completa

O modo mais direto e aprender todas as receitas da profissao. Esse comando
tambem define a habilidade no maximo:

```text
.learn all recipes <profissao-em-ingles>
```

Selecione antes o retrato do personagem que recebera a profissao. Para aplicar
em si mesmo, clique no proprio retrato.

Exemplos:

```text
.learn all recipes alchemy
.learn all recipes blacksmithing
.learn all recipes enchanting
.learn all recipes engineering
.learn all recipes herbalism
.learn all recipes inscription
.learn all recipes jewelcrafting
.learn all recipes leatherworking
.learn all recipes mining
.learn all recipes skinning
.learn all recipes tailoring
.learn all recipes cooking
.learn all recipes first aid
.learn all recipes fishing
```

O nome deve ser escrito em ingles porque o cliente e os dados principais desta
instalacao usam `enUS`.

### Aprender todas as profissoes e receitas

```text
.learn all crafts
```

Esse comando aprende todas as profissoes primarias, secundarias e receitas
disponiveis. Ele ignora o limite normal de duas profissoes primarias e deve ser
usado apenas em personagem de teste/GM.

### Adicionar ou ajustar somente a habilidade

```text
.setskill <skillID> <nivelAtual> [nivelMaximo]
```

Esse comando tambem atua no personagem selecionado.

Exemplos para WotLK 3.3.5a:

```text
.setskill 171 450 450
.setskill 186 450 450
.setskill 333 450 450
.setskill 356 450 450
```

Esses exemplos definem:

- `171`: Alchemy;
- `186`: Mining;
- `333`: Enchanting;
- `356`: Fishing.

IDs de profissao confirmados no core instalado:

| Profissao | ID |
|---|---:|
| First Aid | 129 |
| Blacksmithing | 164 |
| Leatherworking | 165 |
| Alchemy | 171 |
| Herbalism | 182 |
| Cooking | 185 |
| Mining | 186 |
| Tailoring | 197 |
| Engineering | 202 |
| Enchanting | 333 |
| Fishing | 356 |
| Skinning | 393 |
| Jewelcrafting | 755 |
| Riding | 762 |
| Inscription | 773 |

`setskill` sozinho nao garante que todas as receitas aparecam. Para isso, use
tambem `.learn all recipes <profissao>`.

### Maximizar habilidades ja conhecidas

Selecione o personagem e execute:

```text
.maxskill
```

Isso maximiza as habilidades que o personagem ja possui para o limite permitido
no nivel atual. Nao e equivalente a aprender todas as receitas.

### Aprender uma receita especifica

Selecione primeiro o personagem que recebera a receita.

Pesquise a magia da receita:

```text
.lookup spell <nome-da-receita>
```

Depois aprenda o `spellID` retornado:

```text
.learn <spellID>
```

Exemplo de fluxo:

```text
.lookup spell flask of endless rage
.learn <spellID-retornado>
```

### Remover receita ou grau

Selecione primeiro o personagem afetado.

```text
.unlearn <spellID>
.unlearn <spellID> all
```

- sem `all`: remove somente o grau informado;
- com `all`: remove todos os graus relacionados.

Remover uma profissao inteira exige identificar e remover os spells de
aprendizado correspondentes. Antes disso, use:

```text
.character check profession
.lookup spell <nome-da-profissao>
```

### Fluxos recomendados

Aprender Alchemy completa:

```text
.learn all recipes alchemy
.character check profession
```

Adicionar Mining 450 e suas tecnicas:

```text
.setskill 186 450 450
.learn all recipes mining
```

Preparar um personagem GM com tudo:

```text
.learn all crafts
.maxskill
.save
```

## 11. Quests

Pesquisar:

```text
.lookup quest <nome>
```

Administrar:

```text
.quest add <questID>
.quest status <questID>
.quest complete <questID>
.quest reward <questID>
.quest remove <questID>
```

Fluxo comum de teste:

```text
.quest add 1234
.quest complete 1234
.quest reward 1234
```

Algumas quests iniciadas por item exigem adicionar o item correspondente.

## 12. Reputacao, honra e titulos

Reputacao:

```text
.lookup faction <nome>
.modify reputation <factionID> <valor>
.modify reputation <factionID> exalted
.character reputation
```

Honra e arena:

```text
.modify honor <quantidade>
.modify arenapoints <quantidade>
.honor add <quantidade>
.honor update
```

Titulos:

```text
.lookup title <nome>
.titles add <titleID>
.titles remove <titleID>
.character titles
```

## 13. Personagens

Informacoes e mudancas:

```text
.character reputation [personagem]
.character titles [personagem]
.character customize [personagem]
.character changerace <personagem>
.character changefaction <personagem>
.character level [personagem] <nivel>
```

Renomear imediatamente:

```text
.character rename <nomeAtual> 0 <nomeNovo>
```

Forcar tela de renomeacao no proximo login:

```text
.character rename <personagem>
```

Mover personagem para outra conta:

```text
.character changeaccount <novaConta> <personagem>
```

Expulsar jogador:

```text
.kick <personagem> [motivo]
```

## 14. Guildas e grupos

```text
.guild create <lider> "Nome da Guilda"
.guild invite <personagem> "Nome da Guilda"
.guild uninvite <personagem>
```

Os nomes de guilda com espacos devem estar entre aspas.

## 15. Instancias

```text
.instance listbinds
.instance unbind all
.instance unbind <mapID> [dificuldade]
```

Use `.instance unbind all` com cuidado: remove todos os vinculos de instancia
do personagem selecionado.

## 16. Eventos

```text
.lookup event <nome>
.event activelist
.event info <eventID>
.event start <eventID>
.event stop <eventID>
```

O inicio/parada por comando nao altera permanentemente o calendario do banco.

## 17. NPCs

Pesquisar e examinar:

```text
.lookup creature <nome>
.npc info
.npc guid
.npc near <distancia>
```

Criar e remover:

```text
.npc add <creatureID>
.npc add temp
.npc delete
```

`add temp` cria um NPC temporario. `.npc add` salva o spawn.

Mover e configurar:

```text
.npc move
.npc set level <nivel>
.npc set model <displayID>
.npc set faction temp <factionID>
.npc set faction permanent <factionID>
.npc set faction original
.npc set spawntime 10m
.npc set wanderdistance <distancia>
.npc set movetype stay
.npc set movetype random
.npc set movetype way NODEL
```

Interacao:

```text
.npc say <texto>
.npc yell <texto>
.npc whisper <personagem> <texto>
.npc playemote <emoteID>
.npc follow start
.npc follow stop
.npc tame
.respawn
```

## 18. Objetos do mundo

Pesquisar e localizar:

```text
.lookup gobject <nome>
.gobject near [distancia]
.gobject target [ID ou nome]
.gobject info
```

Criar e remover:

```text
.gobject add <ID> [tempoRespawn]
.gobject add temp <ID>
.gobject delete <GUID>
```

Manipular:

```text
.gobject activate <GUID>
.gobject move <GUID>
.gobject turn <GUID>
.gobject respawn <GUID>
.gobject set phase <GUID> <phaseMask>
```

## 19. Playerbots: conceitos

Existem dois grupos principais:

- **randombots**: populam o mundo automaticamente;
- **altbots/addclass bots**: entram sob controle de um jogador.

O servidor atual mantem 100 randombots. Nao use comandos
de reinicializacao global sem necessidade.

Comandos administrativos do modulo comecam com:

```text
.playerbots
```

Comandos de comportamento sao enviados por sussurro ao bot:

```text
/w NomeDoBot follow
```

Tambem e possivel abrir o chat, selecionar sussurro e escolher o bot.

## 20. Playerbots: adicionar e remover bots controlados

Listar bots disponiveis/controlados:

```text
.playerbots bot list
.playerbots bot lookup
```

Adicionar personagem existente como bot:

```text
.playerbots bot add <personagem>
.playerbots bot login <personagem>
```

Remover/desconectar:

```text
.playerbots bot remove <personagem>
.playerbots bot logout <personagem>
.playerbots bot rm <personagem>
```

Adicionar todos os personagens de uma conta permitida:

```text
.playerbots bot addaccount <conta>
```

Criar/adicionar bot por classe:

```text
.playerbots bot addclass warrior
.playerbots bot addclass paladin female
.playerbots bot addclass hunter male
.playerbots bot addclass rogue
.playerbots bot addclass priest
.playerbots bot addclass shaman
.playerbots bot addclass mage
.playerbots bot addclass warlock
.playerbots bot addclass druid
.playerbots bot addclass dk
```

Generos aceitos: `male`, `female`, `0` ou `1`.

## 21. Playerbots: comandos por sussurro

Movimento:

```text
/w NomeDoBot follow
/w NomeDoBot stay
/w NomeDoBot flee
/w NomeDoBot runaway
/w NomeDoBot grind
```

Combate:

```text
/w NomeDoBot attack
/w NomeDoBot tank attack
/w NomeDoBot pull
/w NomeDoBot max dps
/w NomeDoBot pet attack
```

Informacao:

```text
/w NomeDoBot target
/w NomeDoBot attackers
/w NomeDoBot dps
/w NomeDoBot quests
/w NomeDoBot rep
/w NomeDoBot pvp stats
/w NomeDoBot rpg status
```

Itens:

```text
/w NomeDoBot items
/w NomeDoBot inv
/w NomeDoBot c
/w NomeDoBot e
/w NomeDoBot ue
/w NomeDoBot t
```

- `items`, `inv` ou `c`: mostra/conta itens.
- `e`: equipa item informado ou vinculado no chat.
- `ue`: desequipa.
- `t`: inicia troca.

Quests e interacao:

```text
/w NomeDoBot accept
/w NomeDoBot talk
/w NomeDoBot r
/w NomeDoBot u
/w NomeDoBot revive
```

Para itens, quests e magias, use links do chat quando necessario. Exemplo:

```text
/w NomeDoBot e [Nome do Item]
```

## 22. Playerbots: estrategias

As estrategias controlam comportamento em combate (`co`), fora de combate
(`nc`) e quando morto (`dead`).

Consultar estrategias:

```text
/w NomeDoBot co
/w NomeDoBot nc
/w NomeDoBot dead
```

Adicionar/remover estrategia segue o formato:

```text
/w NomeDoBot co +<estrategia>
/w NomeDoBot co -<estrategia>
/w NomeDoBot nc +<estrategia>
/w NomeDoBot nc -<estrategia>
```

Exemplos:

```text
/w NomeDoBot nc +follow
/w NomeDoBot nc -grind
/w NomeDoBot co +dps
/w NomeDoBot co +tank
/w NomeDoBot co +heal
```

Nem toda estrategia existe para todas as classes. Consulte a resposta do bot.

## 23. Playerbots: inicializacao e manutencao

Inicializar bot addclass com equipamento:

```text
.playerbots bot init=auto <personagem>
.playerbots bot init=uncommon <personagem>
.playerbots bot init=rare <personagem>
.playerbots bot init=epic <personagem>
.playerbots bot init=legendary <personagem>
.playerbots bot init=<gearScore> <personagem>
```

Atualizar bot:

```text
.playerbots bot levelup <personagem>
.playerbots bot refresh <personagem>
.playerbots bot quests <personagem>
.playerbots bot refresh=raid <personagem>
```

Aplicar em bots do grupo usando `*`:

```text
.playerbots bot refresh *
```

Recarregar configuracao do modulo:

```text
.playerbots bot reload
```

Monitor de desempenho:

```text
.playerbots pmon
.playerbots pmon tick
.playerbots pmon stack
.playerbots pmon toggle
.playerbots pmon reset
```

## 24. Randombots administrativos

Estatisticas:

```text
.playerbots rndbot stats
```

Atualizar IA:

```text
.playerbots rndbot update
```

Recarregar configuracao:

```text
.playerbots rndbot reload
```

Operacoes em bot especifico ou padrao de nome:

```text
.playerbots rndbot refresh <nome>
.playerbots rndbot levelup <nome>
.playerbots rndbot teleport <nome>
.playerbots rndbot revive <nome>
.playerbots rndbot grind <nome>
.playerbots rndbot change_strategy <nome>
```

Sem nome, algumas operacoes usam `%` e podem afetar todos os randombots.

### Populacao regional pelo host

A conta GM configurada como host ativa a distribuicao regional quando entra com
um personagem. Dos 100 bots, a meta e manter 20 na zona do host, 30 em ate tres
zonas proximas e 50 distribuidos normalmente pelo mundo.

```text
.playerbots region status
.playerbots region pause
.playerbots region resume
.playerbots region rebalance
.playerbots region clear
```

- `status`: mostra host, mapa, zona, zonas proximas e bots em deslocamento.
- `pause`: pausa novas atribuicoes sem desconectar bots.
- `resume`: retoma e agenda um rebalanceamento.
- `rebalance`: forca nova avaliacao no proximo ciclo.
- `clear`: encerra o estado regional; o host precisa reconectar para inicia-lo novamente.

A configuracao manual fica no bloco `AiPlayerbot.RegionalPopulation` de
`env/dist/etc/modules/playerbots.conf`. O recurso considera a conta GM mesmo
com `.gm off`; nao seleciona outro jogador como host se essa conta estiver offline.

## 25. Anuncios

```text
.announce <mensagem>
.notify <mensagem>
.gmannounce <mensagem>
.gmnotify <mensagem>
```

- `announce`: mensagem global no chat.
- `notify`: aviso global na tela.
- variantes `gm`: direcionadas ao contexto de GMs.

## 26. Informacoes do servidor

```text
.server info
.server motd
.server debug
```

Recarregar configuracao:

```text
.reload config
```

Nem toda opcao aceita recarga; algumas exigem reinicio do `worldserver`.

## 27. Comandos perigosos

Os comandos abaixo podem apagar dados, interromper o servidor ou alterar muitos
bots. Confirme alvo e argumentos antes de usar.

### Personagens e inventario

```text
.character erase <personagem>
.character deleted delete <GUID ou nome>
.character deleted purge [dias]
.reset items all <personagem>
.reset items allbags <personagem>
.reset level <personagem>
.reset spells <personagem>
.reset talents <personagem>
```

### Mundo

```text
.npc delete
.gobject delete <GUID>
```

### Randombots

```text
.playerbots rndbot reset
.playerbots rndbot clear
.playerbots rndbot init
```

`rndbot reset` limpa o estado de randombots e pede reinicio do servidor.

### Servidor

```text
.server restart <tempo>
.server restart cancel
.server shutdown <tempo>
.server shutdown cancel
.server exit
```

Exemplos de tempo:

```text
.server restart 30s
.server shutdown 5m
```

Nao use `.server exit` ou `.server shutdown` durante operacoes de banco ou sem
salvar os personagens.

## 28. Sequencias praticas

Preparar o proprio personagem para testes:

```text
.gm on
.cheat god on
.cheat cooldown on
.modify speed all 2
.levelup 79
.learn all my class
.learn all my trainer
.maxskill
.modify money 1000000
.save
```

Encontrar e obter um item:

```text
.lookup item frostmourne
.additem <ID retornado> 1
```

Testar uma quest:

```text
.lookup quest <nome>
.quest add <ID>
.quest complete <ID>
.quest reward <ID>
```

Montar grupo com bot:

```text
.playerbots bot addclass paladin
.playerbots bot list
```

Depois convide o bot para o grupo e envie:

```text
/w NomeDoBot follow
/w NomeDoBot co +tank
```

## 29. Referencia da instalacao

Fontes locais usadas para este guia:

- ajuda oficial da tabela `acore_world.command`;
- `src/server/scripts/Commands/`;
- `modules/mod-playerbots/src/Script/PlayerbotCommandScript.cpp`;
- `modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp`;
- `modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp`;
- configuracao `env/dist/etc/modules/playerbots.conf`.

Para obter a sintaxe mais atual durante o jogo:

```text
.commands
.help <comando>
```
