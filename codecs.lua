-- codecs.lua (trecho alterado)
local Codecs = {}

local ImageCodec = require("image_codec")
local PassThroughCodec = require("pass_through_codec")
local IgnoreCodec = require("ignore_codec")
local TiledCodec = require("tiled_codec")
local FurCodec = require("fur_codec")          -- NOVO
local Validator = require("tiled_validator")

function Codecs.get_codec(filename, full_path)
  if filename:match("%.png$") then
    return ImageCodec
  elseif filename:match("palette%.lua$") then
    return IgnoreCodec
  elseif filename:match("%.lua$") then
    return PassThroughCodec
  elseif filename:match("%.json$") then
    if Validator.is_tiled_map(full_path) then
      return TiledCodec
    end
    return IgnoreCodec
  elseif filename:match("%.fur$") then           -- NOVO BLOCO
    return FurCodec
  else
    return IgnoreCodec
  end
end

return Codecs
