# Validacao do Compose

Data: 2026-06-11

Escopo:

- checkout real do AzerothCore Playerbot no commit fixado;
- modulo Playerbots no commit fixado;
- Compose consolidado com o override local;
- analise estatica, sem `build`, `pull` ou `up`.

Resultados:

- cinco servicos resolvidos pelo Compose;
- banco MySQL sem porta publicada no host;
- authserver em `127.0.0.1:3724`;
- worldserver em `127.0.0.1:8085`;
- nenhum servico privilegiado ou acesso ao socket Docker;
- `no-new-privileges` e rotacao local de logs em todos os servicos;
- MySQL 8.4.9 e Ubuntu 24.04 fixados por digest `linux/amd64`;
- imagens locais identificadas pelo commit curto do core;
- compilacao limitada a quatro tarefas paralelas;
- senha do banco obrigatoria e gerada localmente antes da execucao;
- dados do cliente fixados pelo core na versao `v19`.

Integridade do client-data:

- a release oficial e imutavel e publica o digest SHA-256 do ativo `Data.zip`;
- digest fixado: `d37f19cbf3d1c57d965882340519e0275e0964554476117791ad06069a667b04`;
- o downloader local exige sucesso HTTP e valida o SHA-256 antes da extracao.

Conclusao:

O Compose esta estruturalmente pronto para a proxima etapa. Nenhuma imagem foi
compilada ou baixada e nenhum container do projeto foi iniciado nesta validacao.
