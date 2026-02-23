extends Area3D

@onready var carimbo_anim = $AnimatedSprite3D
@onready var espinho_anim = $EspinhosSprite

var dano_ativo = false	

func _ready():
	carimbo_anim.play("carimbar") 
	await get_tree().create_timer(1.0).timeout
	
	espinho_anim.visible = true
	espinho_anim.play("crescer")
	dano_ativo = true
	
	causar_dano_em_area()
	
	await get_tree().create_timer(1.5).timeout
	queue_free()

func causar_dano_em_area():
	var corpos = get_overlapping_bodies()
	for corpo in corpos:
		if corpo.has_method("receber_dano"):
				corpo.receber_dano("poder") # Essa linha precisa estar identada!
