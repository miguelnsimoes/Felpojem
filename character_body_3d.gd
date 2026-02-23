extends CharacterBody3D

const SPEED = 5.0
const SPEED_AGACHADO = 2.0
const JUMP_VELOCITY = 4.5
var vida = 10
 
@export var cena_do_poder: PackedScene
@onready var anim = $AnimatedSprite3D 
@onready var area_ataque = $AreaAtaque

var atacando = false
var esta_agachado = false
var poder_equipado: PackedScene = null
var can_parry = false
var is_parried = false
var enemy_name = ""
var gliding = false

func _physics_process(_delta):
	
	var input_guard = Input.is_action_just_pressed("defesa")
	if input_guard:
		print("tentou parry")
		
	if input_guard and can_parry:
		can_parry = false
		is_parried = true

		var enemy = get_tree().root.find_child(enemy_name, true, false)
		if enemy and enemy.has_method("got_parried") and enemy != self:
			print("parried")
			enemy.got_parried()
		return 
		
	if atacando:
		return

	var multiplierGravity = 1.0
	var multiplierSpeed = 1.0

	if not is_on_floor():
		if gliding and velocity.y < 0:
			multiplierGravity = 0.25
		
		velocity += get_gravity() * _delta * multiplierGravity

	if Input.is_action_just_pressed("jump"):   
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			gliding = false
		elif velocity.y < 2.5:
			gliding = true
			
	var velocidade_atual = SPEED
	
	if Input.is_action_pressed("agachar"):
		esta_agachado = true
		velocidade_atual = SPEED_AGACHADO
	else:
		esta_agachado = false

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direcao = Vector3(input_dir.x, 0, input_dir.y)

	if direcao != Vector3.ZERO:
		if gliding and velocity.y < 0:
			multiplierSpeed = 0.75
			
		velocity.x = direcao.x * velocidade_atual * multiplierSpeed
		velocity.z = direcao.z * velocidade_atual * multiplierSpeed
		area_ataque.position = direcao * 1.0
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)
		velocity.z = move_toward(velocity.z, 0, velocidade_atual)
	
	move_and_slide()
	set_animation()
	
	if Input.is_action_just_pressed("atacar"):
		iniciar_ataque()
	if Input.is_action_just_pressed("carimbar"):
		if poder_equipado != null:
			executar_carimbo_especifico(poder_equipado)
			

func set_animation():
	if atacando: 
		return

	if velocity.x > 0.1: 
		anim.flip_h = false
	elif velocity.x < -0.1:
		anim.flip_h = true

	var colidindo_com_parede = false
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var objeto = colisao.get_collider()
		if objeto is CSGBox3D or "Parede" in objeto.name:
			if abs(colisao.get_normal().x) > 0.5 or abs(colisao.get_normal().z) > 0.5:
				colidindo_com_parede = true

	#orderm tem prioridade
	if colidindo_com_parede:
		anim.play("parada")
	elif esta_agachado: 
		anim.play("agachar") 
	elif velocity.length() > 0.2:
		anim.play("andar")
	else:
		anim.play("parada")

func executar_carimbo_especifico(cena):
	var novo_carimbo = cena.instantiate()
	get_parent().add_child(novo_carimbo)
	var pos = global_position
	pos.y = 0.05 
	novo_carimbo.global_position = pos

func iniciar_ataque():
	atacando = true
	anim.play("bater")
	var corpos_na_area = area_ataque.get_overlapping_bodies()
	for corpo in corpos_na_area:
		if corpo.has_method("receber_dano") and corpo != self:
			await get_tree().create_timer(0.3).timeout
			corpo.receber_dano()
	await anim.animation_finished
	atacando = false
	
func receber_dano(enemy_name_var):
	enemy_name = enemy_name_var 
	can_parry = true
	
	await get_tree().create_timer(0.1).timeout
	can_parry = false

	if !can_parry and !is_parried:
		vida -= 1
		anim.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.15).timeout
		anim.modulate = Color(1, 1, 1)
		
		if vida <= 0:
			morrer()

	if is_parried:
		is_parried = false


func morrer():
	get_tree().reload_current_scene()

var inventario = []
var inventario_aberto = false

func _ready():
	$Interface/FundoInventario.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("abrir_inventario"):
		alternar_inventario()
		

func alternar_inventario():
	inventario_aberto = !inventario_aberto
	
	if inventario_aberto:
		$Interface/FundoInventario.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_atualizar_tela_inventario()
	else:
		$Interface/FundoInventario.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func adicionar_ao_inventario(dados):
	inventario.append(dados)
	if dados.has("poder_cena"):
		poder_equipado = dados["poder_cena"]


func _atualizar_tela_inventario():
	var grade = $Interface/FundoInventario/GridContainer
	
	for n in grade.get_children(): #pra nao dar loop no item
		n.queue_free()
	
	for item in inventario:
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(80, 80)

		if item["icone"] != null:
			botao.icon = item["icone"]
			botao.expand_icon = true 
		else:
			botao.text = item["nome"] 
			
		grade.add_child(botao)
		
		
		

	 	
