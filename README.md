# lupi-codec

Processa uma pasta de jogo (sprites, mapas e scripts) e gera um release otimizado com manifesto, paleta de cores e arquivos convertidos para o formato do motor Lupi.

## Requisitos

- Lua 5.3 ou superior
- ImageMagick (`magick` disponível no `PATH`)

## Uso

```bash
lua run.lua <pasta_entrada> <pasta_saida>
```

### Exemplo

```bash
lua run.lua ../meu-jogo /tmp/meu-jogo-release
```

## O que acontece

1. Copia os arquivos do projeto para `<pasta_saida>/releases/<timestamp>/`.
2. Processa as imagens PNG:
   - Extrai as cores e converte para BGR555.
   - Detecta tiles automaticamente.
   - Trata e limita o mapeamento de cores (máximo de 256 cores por imagem/paleta).
   - Remove os PNGs originais do release após o processamento.
3. Converte mapas exportados pelo Tiled em formato JSON (`.json`) para scripts Lua.
4. Ignora arquivos não necessários ao formato final.
5. Gera `palette.lua` e atualiza `master_palette.json`.
6. Gera `lupi_manifest.txt` com metadados dos arquivos processados.
7. Cria o link simbólico `current`, apontando para o release gerado.

## Mapas do Tiled: tratamento de camadas

O codec aceita mapas do Tiled exportados em JSON (`.json`) e processa somente camadas do tipo **Tile Layer** (`tilelayer`).

Camadas de outros tipos — como **Object Layer** (`objectgroup`), **Image Layer** (`imagelayer`) e **Group Layer** (`group`) — são ignoradas durante a conversão. Elas são removidas apenas da estrutura JSON carregada em memória pelo codec; o arquivo JSON original do projeto não é alterado por esse filtro.

Quando um mapa contém camadas suportadas e não suportadas, o processamento continua usando apenas as camadas `tilelayer`, em vez de interromper a conversão por causa das camadas incompatíveis. O codec também informa no terminal quais camadas foram ignoradas.

**Importante:**
- O suporte continua limitado a camadas `tilelayer`; camadas de grupo não são abertas nem achatadas para processar suas camadas filhas.
- As camadas ignoradas não são convertidas para Lua e não aparecem no mapa gerado.
- As demais validações do mapa e dos tilesets continuam sendo aplicadas normalmente.
- O filtro não modifica o arquivo-fonte JSON. Como parte do pipeline, o codec pode excluir a cópia `.json` presente no release depois de gerar o `.lua`; mantenha o arquivo original do projeto como fonte.

### Vantagens

- **Menos interrupções:** uma camada incompatível não impede a conversão das camadas de tiles que são suportadas.
- **Fluxo de trabalho mais simples:** não é necessário editar e exportar novamente o mapa apenas para remover camadas que o codec não utiliza.
- **Comportamento previsível:** somente camadas `tilelayer` participam da geração do mapa Lua.
- **Diagnóstico claro:** o terminal lista as camadas ignoradas, facilitando identificar o que não entrou no resultado.

## Tratamento da Paleta e Limite de 256 Cores (`PixelIndexer`)

Para garantir a estabilidade do enquadramento de imagens em diferentes sistemas e ambientes (como CachyOS, WSL Ubuntu, etc.), o codificador aplica travas de segurança na alocação de cores:

### O Problema Resolvido
O formato de imagem utiliza exatamente **1 byte por pixel** para referenciar a paleta de cores (intervalo de `0` a `255`, mapeado via `string.char(index - 1)`). Em imagens com muitas cores únicas ou variações causadas pela ordem de hash do interpretador Lua em diferentes compilações/sistemas, a criação de cores podia ultrapassar 256 entradas (gerando o erro `bad argument #1 to 'char' (value out of range)`).

### Correções Aplicadas

1. **`pixel_indexer.lua`**:
   - Adicionada uma trava de segurança na função `add_new_color`. Quando a paleta atinge o limite máximo de **256 cores**, qualquer cor excedente utiliza um mecanismo de *fallback* para o último índice válido (`256`), evitando o estouro de byte.

2. **`image_encoder.lua`**:
   - Adicionada uma validação defensiva na função `encode_pixel_at` para interceptar e diagnosticar imediatamente qualquer índice fora do intervalo permitido (`0` a `255`) antes de realizar a conversão com `string.char`.

## Estrutura de saída

```text
<pasta_saida>/
  current/ -> releases/<timestamp>/
  master_palette.json
  releases/
    <timestamp>/
      lupi_manifest.txt
      palette.lua
      ... (arquivos processados)
```

## Arquivos principais

- `run.lua` — orquestra o processamento e a geração do release.
- `manifest.lua` — gera e salva o manifesto.
- `pipeline.lua` — aplica os codecs aos arquivos do release.
- `codecs.lua` — seleciona o codec de acordo com o arquivo.
- `image_codec.lua` — converte PNGs para bitmap indexado.
- `pixel_indexer.lua` — gerencia o índice de pixels e aplica o limite de 256 cores.
- `image_encoder.lua` — codifica os dados brutos de imagem e valida intervalos de bytes.
- `tiled_codec.lua` — converte mapas Tiled JSON para Lua e filtra camadas não suportadas.
- `tiled_validator.lua` — valida os atributos de mapas, camadas e tilesets.
- `pass_through_codec.lua` — mantém arquivos Lua sem conversão.
- `ignore_codec.lua` — identifica arquivos que devem ser ignorados.
- `colors_manager.lua` — gerencia a paleta de cores.
- `dkjson.lua` — biblioteca JSON escrita em Lua.

## Observações

- O processamento é feito em uma cópia dentro do diretório de release; não edite o mapa-fonte para contornar o filtro de camadas.
- O filtro de camadas não substitui as validações de compatibilidade restantes do codec.