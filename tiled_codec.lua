local json = require("dkjson")
local Validator = require("tiled_validator")
local Processor = require("tiled_processor")
local Generator = require("tiled_generator")

local TiledCodec = {}

local function report_removed_layers(layers)
  if #layers == 0 then
    return
  end

  print(string.format(
    "Aviso: %d camada(s) nao suportada(s) foram removida(s):",
    #layers
  ))

  for _, layer in ipairs(layers) do
    print(string.format(
      "  - %s (%s)",
      layer.name or "<sem nome>",
      layer.type or "<tipo desconhecido>"
    ))
  end
end

function TiledCodec.process(filepath, relative_path, _context)
  local path = relative_path
  local f = io.open(filepath, "rb")
  if not f then return nil end
  local content = f:read("*all")
  f:close()

  local ok, map = pcall(json.decode, content)
if not ok or not map then
  print("Erro ao decodificar JSON: " .. relative_path)
  return { { type = "DELETE", path = relative_path } }
end

  Validator.validate_map_attributes(map)

  local removed_layers = Validator.filter_unsupported_layers(map)
  report_removed_layers(removed_layers)

  -- Avisa se o mapa ficou sem camadas
  if #map.layers == 0 then
    print("Aviso: O mapa " .. relative_path .. " nao possui nenhuma camada de tile! isso esta correto ?")
  end

  Validator.validate_reserved_layer_names(map.layers)

  local sorted_tilesets, tileset_dictionary = Processor.process_tilesets(map)
  local processed_layers = {}

  for _, layer in ipairs(map.layers) do
    Validator.validate_layer_attributes(layer)

    local data = Processor.process_layer_data(layer, sorted_tilesets)

    table.insert(processed_layers, {
      name = layer.name,
      data = data
    })
  end

  local lua_content = Generator.generate_lua_map_string(
    map,
    processed_layers,
    tileset_dictionary
  )

  return {
    { type = "DELETE", path = path },
    {
      type = "NEW",
      path = path:gsub("%.json$", ".lua"),
      content = lua_content,
      metadata = {
        type = "lua_code"
      }
    }
  }
end

return TiledCodec
