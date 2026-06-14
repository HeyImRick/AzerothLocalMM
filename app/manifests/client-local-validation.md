# Validacao do cliente local

Data: 2026-06-12

- cliente WotLK 3.3.5a extraido em area isolada do projeto;
- `realmlist` configurado para `127.0.0.1`;
- realm configurado como `AzerothCore`;
- portal e patchlist remotos removidos;
- cliente executado em prefixo Wine dedicado;
- `gxCursor=0` aplicado para usar cursor por software e evitar intermitencia
  do cursor nos menus sob Wine;
- nome da conta e nome do personagem confirmados como campos independentes;
- filtro DBC de nomes reservados desativado no servidor privado;
- personagem renomeado pelo comando oficial do AzerothCore, sem edicao SQL.
