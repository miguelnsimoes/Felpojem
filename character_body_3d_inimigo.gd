extends CharacterBody3D

const SPEED = 3.0
const DISTANCIA_ATAQUE = 1.5
const RAIO_VISAO = 7.0  
const ANGULO_VISAO = 90.0 

var vida = 3
var atacando = false
var percebeu_player = false
var parried = false

@onready var anim = $AnimatedSprite3D
@onready var area_ataque = $AreaAtaque
@onready var raycast = $VisaoRayCast 
@onready var player = get_tree().root.find_child("CharacterBody3D", true, false)

func _physics_process(_delta):
	if not player or not raycast or atacando:
		return

	var distancia = global_position.distance_to(player.global_position)
	var direcao_ao_player = global_position.direction_to(player.global_position)
	direcao_ao_player.y = 0 
	
	if not percebeu_player:
		if distancia <= RAIO_VISAO:
			raycast.target_position = raycast.to_local(player.global_position)
			raycast.force_raycast_update()
			
			var tem_linha_de_visao = false
			if raycast.is_colliding() and raycast.get_collider() == player:
				tem_linha_de_visao = true 

			if tem_linha_de_visao:
				if not player.esta_agachado:	
					percebeu_player = true
				else:
					var direcao_olhar = Vector3.RIGHT if not anim.flip_h else Vector3.LEFT
					var angulo_entre_eles = rad_to_deg(direcao_olhar.angle_to(direcao_ao_player))
					
					if angulo_entre_eles <= ANGULO_VISAO:
						percebeu_player = true

	if percebeu_player:
		if distancia > DISTANCIA_ATAQUE:
			velocity.x = direcao_ao_player.x * SPEED
			velocity.z = direcao_ao_player.z * SPEED
			anim.play("andar")
			anim.flip_h = direcao_ao_player.x < 0
		else:
			velocity.x = 0
			velocity.z = 0
			iniciar_ataque_inimigo()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func iniciar_ataque_inimigo():
	if atacando: 
		return
	atacando = true
	anim.play("bater")
	
	await get_tree().create_timer(0.4).timeout
	
	var corpos = area_ataque.get_overlapping_bodies()
	for corpo in corpos:
		if corpo.has_method("receber_dano") and corpo != self:
			corpo.receber_dano(self.name)

	await get_tree().create_timer(1.0).timeout
	atacando = false


func receber_dano(_tipo_de_dano = ""):
	percebeu_player = true 
	vida -= 1
	anim.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)
	
	if vida <= 0:
		queue_free()
		

func got_parried():
	parried = true
	#animPlayer.play("parry")
	anim.modulate = Color(1, 1, 0) 
	print('parried')
	await get_tree().create_timer(2.0).timeout
	anim.modulate = Color(1, 1, 1)
	parried = false
