# Build incremental do Azeroth Local

O build incremental usa um container de desenvolvimento e mantem todos os
artefatos pesados no NVMe:

- `var/build`: arvore persistente do CMake/Ninja;
- `var/ccache`: cache persistente de compilacao;
- `var/dist/bin/worldserver`: binario pronto para implantacao.

## Comandos

Validar sem compilar:

```bash
./app/scripts/preflight-incremental-build.sh
```

Compilar:

```bash
./app/scripts/run-incremental-build.sh
```

Implantar o binario e recriar apenas o worldserver:

```bash
./app/scripts/deploy-incremental-worldserver.sh
```

A primeira execucao precisa criar a imagem do toolchain e gerar a arvore base,
portanto sera mais demorada. As execucoes seguintes reutilizam Ninja e ccache,
compilam apenas os fontes alterados e relinkam o `worldserver`.

Alteracoes apenas em `env/dist/etc/modules/playerbots.conf` nao exigem build.
Nesse caso basta recriar o worldserver.
