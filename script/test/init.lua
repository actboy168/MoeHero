
require 'test.memory_test'
local player = require 'ac.player'
local console = require 'jass.console'

if not base.release then
	require 'test.helper'
end

if player.countAlive() == 1 then
	console.enable = true
	require 'test.helper'
end

require 'test.global'
require 'test.pairs'
