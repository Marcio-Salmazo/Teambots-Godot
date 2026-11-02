# Indica que a classe herda de Resource.
extends Resource
class_name DialogueData
# O DialogueData utiliza o sistema de recursos (Resources) da Godot 
# para armazenar informações relacionadas a uma conversa.
@export var speaker: String = ""
@export var lines: Array[String] = []
