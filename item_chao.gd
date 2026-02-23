extends Node3D

@export var nome_do_item: String = "Item"
@export var descricao_do_item: String = "bilhete da filha depressiva"
@export var icone_do_item: Texture2D
@export var cena_do_poder_para_usar: PackedScene

var player_perto = false
var player_ref = null

func _process(_delta):
	if player_perto and Input.is_action_just_pressed("interagir"):
		pegar_item()

func pegar_item():
	if player_ref:
		var dados_completos = {
			"nome": nome_do_item,
			"descricao": descricao_do_item,
			"icone": icone_do_item,
			"poder_cena": cena_do_poder_para_usar
		}

		player_ref.adicionar_ao_inventario(dados_completos)
		queue_free()

func _on_area_3d_body_entered(body):
	if body.name == "CharacterBody3D":
		player_perto = true
		player_ref = body

func _on_area_3d_body_exited(body):
	if body.name == "CharacterBody3D":
		player_perto = false
		player_ref = null
