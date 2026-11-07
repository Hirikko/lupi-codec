-- fur_codec.lua
local FurCodec = {}

function FurCodec.process(filepath, relative_path, _context)
  -- Lê o conteúdo binário do arquivo .fur
  local f = io.open(filepath, "rb")
  if not f then
    -- Se não for possível ler, remove o arquivo para não quebrar o release
    return { { type = "DELETE", path = relative_path } }
  end
  local content = f:read("*a")
  f:close()

  -- Gera o novo caminho removendo a extensão .fur
  local new_path = relative_path:gsub("%.fur$", "")

  -- Retorna: (1) criação do arquivo sem extensão, (2) exclusão do .fur original
  return {
    {
      type = "NEW",
      path = new_path,
      content = content,
      metadata = { type = "binary" } -- ou "asset", se preferir
    },
    {
      type = "DELETE",
      path = relative_path
    }
  }
end

return FurCodec
