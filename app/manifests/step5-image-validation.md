# Validacao das imagens da etapa 5

Data: 2026-06-12

Resultado:

- build concluido com sucesso;
- quatro imagens locais `linux/amd64` identificadas pelo commit `82d3bf237d51`;
- `worldserver` e `authserver` executaveis e sem dependencias dinamicas ausentes;
- `dbimport` executavel e arquivos SQL presentes;
- configuracao do Playerbots instalada em
  `/azerothcore/env/ref/etc/modules/playerbots.conf.dist`;
- Playerbots habilitado no arquivo de referencia;
- limites locais de 20 a 40 bots resolvidos pelo Compose;
- `.env` privado presente com permissao `0600`;
- nenhum container do projeto criado ou iniciado.

Imagens:

- worldserver: `sha256:8f5c20a24781baa558df8118b31ec33769f02aadcfe56dceb21540e124c56b0d`;
- authserver: `sha256:a281c28a9dbd3bfde98e2a52d7bb954d6c67d48c28235d16e62d5cc72d462394`;
- db-import: `sha256:fd47b43d08b6930bda95139a75ed33dc19379bc33d65f7b4631f05ce043534b8`;
- client-data: `sha256:f8241b611be9d57dbf7ed02455ced28c1b25edcb5975bece08811a28cce5bfcb`.

Proxima etapa:

- inicializar client-data, banco e servicos de forma controlada;
- acompanhar download, importacao e migrations;
- validar portas apenas em localhost e saude dos processos.
