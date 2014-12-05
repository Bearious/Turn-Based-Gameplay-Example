-----------------------------------------------------------------------------------------
-- Turn based gameplay example
-- Made by Garrett Savo (garrettsavo@gmail.com) - 12/5/2014
-----------------------------------------------------------------------------------------

display.setDefault( "magTextureFilter", "nearest" )
display.setDefault( "minTextureFilter", "linear" )
W_ = display.contentWidth
H_ = display.contentHeight

ui = require("ui")
MiddleClass = require("MiddleClass")
MindState = require("MindState")
GameClass = require("GameClass")

Display = require("Display")
Start = require("Start")

QuestClass = require("Quest")
QuestListFile = require("QuestList")

HeroClass = require("Hero")
HeroListFile = require("HeroList")

EnemyClass = require("Enemy")
EnemyListFile = require("EnemyList")

myMusic = audio.loadSound("Music/Battle.mp3")

Game = GameObject:new()
Game:gotoState("Start")

