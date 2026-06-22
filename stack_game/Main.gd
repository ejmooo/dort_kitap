extends Node2D
## Stack Tower — tek sahnelik (Main.tscn) tam oyun.
## Tüm UI ve oyun nesneleri kod içinde oluşturulur (bozuk .tscn riski yok).
## Görseller tamamen prosedüreldir (ColorRect + HSV ton kaydırma). Asset gerekmez.

# ============================================================================
#  AYARLANABİLİR SABİTLER (tüm "sihirli sayılar" burada toplanır)
# ============================================================================
const REF_W: float = 1080.0          # referans tasarım genişliği
const REF_H: float = 1920.0          # referans tasarım yüksekliği

const BASE_SPEED: float = 220.0      # başlangıç yatay hızı (px/s)
const SPEED_INC: float = 4.0         # her bloktan sonra hız artışı
const MAX_SPEED: float = 520.0       # üst hız sınırı

const START_WIDTH: float = 460.0     # başlangıç blok genişliği
const MIN_WIDTH: float = 8.0         # bu genişliğin altında OYUN BİTER
const BLOCK_HEIGHT: float = 64.0     # blok yüksekliği

const PERFECT_THRESHOLD: float = 12.0  # |delta| <= bu ise "Mükemmel"
const PERFECT_REGROW: float = 14.0     # 3 ardışık perfect'te geri büyüme
const PERFECT_STREAK_FOR_REGROW: int = 3

const HUE_STEP: float = 0.012        # her katmanda HSV ton kayması
const BLOCK_SAT: float = 0.55        # blok doygunluğu
const BLOCK_VAL: float = 0.95        # blok parlaklığı

const SCROLL_TIME: float = 0.12      # kule yukarı kayma süresi
const FALL_TIME: float = 0.8         # kesilen parça düşme süresi
const FALL_DISTANCE: float = 700.0   # düşen parça mesafesi

const PLAY_Y_RATIO: float = 0.60     # aktif bloğun ekrandaki sabit y oranı

# Rüzgâr (TWIST 2): skor 10'un katlarında devreye girer, hafif salınım.
const WIND_START_SCORE: int = 10
const WIND_AMP_PER_LEVEL: float = 3.0  # her 10 skorda genlik artışı (px)
const WIND_AMP_MAX: float = 26.0       # genlik üst sınırı (asla sinir bozucu olmasın)
const WIND_FREQ: float = 2.2           # salınım frekansı

# Coin ödülleri
const COIN_PER_PERFECT: int = 1
const COMBO_BONUS_THRESHOLD: int = 5   # combo>=5 iken ekstra coin
const COMBO_BONUS_COINS: int = 2

# ============================================================================
#  PALETLER (mağaza) — base_hue + arka plan rengi + fiyat
# ============================================================================
const PALETTES: Array = [
	{"name": "Klasik",      "hue": 0.55, "bg": Color(0.09, 0.11, 0.16), "price": 0},
	{"name": "Gün Batımı",  "hue": 0.03, "bg": Color(0.17, 0.07, 0.10), "price": 50},
	{"name": "Orman",       "hue": 0.33, "bg": Color(0.06, 0.13, 0.09), "price": 120},
	{"name": "Okyanus",     "hue": 0.52, "bg": Color(0.05, 0.12, 0.16), "price": 200},
	{"name": "Lavanta",     "hue": 0.75, "bg": Color(0.13, 0.09, 0.17), "price": 350},
	{"name": "Şeker",       "hue": 0.88, "bg": Color(0.17, 0.08, 0.14), "price": 500},
]

# ============================================================================
#  DURUMLAR (state machine)
# ============================================================================
enum State { MENU, PLAYING, GAMEOVER, SHOP }
var state: int = State.MENU

# ============================================================================
#  OYUN DURUM DEĞİŞKENLERİ
# ============================================================================
var world: Node2D                    # tüm blokların kabı (yukarı kaydırılır)
var blocks: Array[ColorRect] = []    # yerleştirilmiş bloklar
var active_block: ColorRect = null   # gidip gelen aktif blok

var top_x: float = 0.0               # en üst bloğun sol kenarı (dünya = ekran x)
var top_width: float = 0.0           # en üst bloğun genişliği
var start_width_eff: float = START_WIDTH  # bu oyundaki etkin başlangıç genişliği

var move_x: float = 0.0              # aktif bloğun gidip gelen sol kenarı
var active_dir: float = 1.0          # +1 sağa, -1 sola
var speed: float = BASE_SPEED

var score: int = 0
var combo: int = 0
var perfect_streak: int = 0
var run_coins: int = 0               # bu oyunda kazanılan coin
var wind_time: float = 0.0

# Ekran boyutları (her oyunda yeniden hesaplanır)
var view_w: float = REF_W
var view_h: float = REF_H
var center_x: float = REF_W * 0.5
var play_y: float = REF_H * PLAY_Y_RATIO

# Streak açılış bilgisi (menüde gösterilir)
var streak_bonus_msg: String = ""

# ============================================================================
#  UI REFERANSLARI
# ============================================================================
var bg_rect: ColorRect

var menu_panel: Control
var menu_best_label: Label
var menu_coin_label: Label
var menu_streak_label: Label
var menu_bonus_label: Label

var hud_panel: Control
var score_label: Label
var hud_coin_label: Label
var perfect_label: Label

var gameover_panel: Control
var go_score_label: Label
var go_best_label: Label
var go_record_label: Label
var go_coins_label: Label

var shop_panel: Control
var shop_coin_label: Label
var shop_list: VBoxContainer


# ============================================================================
#  YAŞAM DÖNGÜSÜ
# ============================================================================
func _ready() -> void:
	_recompute_view()
	_build_world()
	_build_ui()

	# Günlük seri kontrolü (açılışta bir kez).
	var streak_info: Dictionary = SaveManager.update_streak()
	if streak_info.get("new_day", false) and int(streak_info.get("bonus", 0)) > 0:
		streak_bonus_msg = "🎁 Günlük bonus: +%d coin" % int(streak_info["bonus"])
	else:
		streak_bonus_msg = ""

	_goto_menu()


func _process(delta: float) -> void:
	if state != State.PLAYING or active_block == null:
		return

	# Aktif bloğu yatayda gidip getir.
	var max_left: float = max(0.0, view_w - top_width)
	move_x += active_dir * speed * delta
	if move_x <= 0.0:
		move_x = 0.0
		active_dir = 1.0
	elif move_x >= max_left:
		move_x = max_left
		active_dir = -1.0

	# TWIST 2: rüzgâr — skor 10'un katlarına ulaştıkça hafif sinüs salınımı.
	var wind: float = 0.0
	if score >= WIND_START_SCORE:
		wind_time += delta
		var level: int = int(score / 10)
		var amp: float = min(float(level) * WIND_AMP_PER_LEVEL, WIND_AMP_MAX)
		wind = sin(wind_time * WIND_FREQ) * amp

	active_block.position.x = clamp(move_x + wind, 0.0, max(0.0, view_w - top_width))


func _unhandled_input(event: InputEvent) -> void:
	if state == State.PLAYING:
		if _is_action_press(event):
			_drop_block()
	elif state == State.MENU:
		# Menüde space ile hızlı başlangıç.
		if event is InputEventKey and event.pressed and not event.echo \
				and (event as InputEventKey).keycode == KEY_SPACE:
			_start_game()


func _is_action_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		return true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			return true
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_SPACE:
			return true
	return false


# ============================================================================
#  GÖRÜNÜM / DÜNYA KURULUMU
# ============================================================================
func _recompute_view() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	view_w = vs.x
	view_h = vs.y
	center_x = view_w * 0.5
	play_y = view_h * PLAY_Y_RATIO


func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)


# ----------------------------------------------------------------------------
#  Renk yardımcıları (prosedürel)
# ----------------------------------------------------------------------------
func _current_palette() -> Dictionary:
	var idx: int = clampi(SaveManager.selected_palette, 0, PALETTES.size() - 1)
	return PALETTES[idx]


func _block_color(idx: int) -> Color:
	var base_hue: float = float(_current_palette()["hue"])
	var hue: float = fmod(base_hue + float(idx) * HUE_STEP, 1.0)
	return Color.from_hsv(hue, BLOCK_SAT, BLOCK_VAL)


func _bg_color() -> Color:
	return _current_palette()["bg"]


# ============================================================================
#  OYUN AKIŞI
# ============================================================================
func _clear_world() -> void:
	for c in world.get_children():
		c.queue_free()
	blocks.clear()
	active_block = null


func _start_game() -> void:
	_recompute_view()
	_clear_world()

	score = 0
	combo = 0
	perfect_streak = 0
	run_coins = 0
	wind_time = 0.0
	speed = BASE_SPEED

	start_width_eff = min(START_WIDTH, view_w * 0.6)
	top_width = start_width_eff
	top_x = center_x - top_width * 0.5

	# Taban blok (index 0).
	var base := _make_rect(top_x, 0.0, top_width, _block_color(0))
	blocks.append(base)

	# Kuleyi öyle konumla ki aktif blok (index 1) play_y'de görünsün.
	world.position = Vector2(0.0, play_y + BLOCK_HEIGHT)

	_spawn_active()

	state = State.PLAYING
	_show_only(hud_panel)
	_update_hud()


func _spawn_active() -> void:
	var idx: int = blocks.size()
	move_x = 0.0
	active_dir = 1.0
	active_block = _make_rect(move_x, -float(idx) * BLOCK_HEIGHT, top_width, _block_color(idx))


## Dünya-yerel koordinatta bir ColorRect oluşturur (left/top_y/width verilir).
func _make_rect(left: float, local_y: float, width: float, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(width, BLOCK_HEIGHT)
	r.position = Vector2(left, local_y)
	r.color = col
	world.add_child(r)
	return r


func _drop_block() -> void:
	if active_block == null:
		return

	var cur_x: float = active_block.position.x   # aktif sol kenar
	var cur_w: float = top_width                 # aktif genişlik = destek genişliği
	var delta: float = cur_x - top_x             # hizasızlık

	if absf(delta) <= PERFECT_THRESHOLD:
		_handle_perfect()
	else:
		_handle_cut(cur_x, cur_w)


# ----------------------------------------------------------------------------
#  TWIST 1: Mükemmel (perfect) yerleştirme
# ----------------------------------------------------------------------------
func _handle_perfect() -> void:
	# Snap: alttakine tam hizala, kesim yok.
	active_block.position.x = top_x
	top_x = active_block.position.x
	blocks.append(active_block)

	combo += 1
	perfect_streak += 1

	# Coin ödülü
	var earned: int = COIN_PER_PERFECT
	if combo >= COMBO_BONUS_THRESHOLD:
		earned += COMBO_BONUS_COINS
	run_coins += earned
	SaveManager.add_coins(earned)

	# 3 ardışık perfect'te kaybedilen genişliğin bir kısmı geri büyür.
	if perfect_streak % PERFECT_STREAK_FOR_REGROW == 0:
		_regrow_top()

	_flash_block(blocks.back())
	_show_perfect_text()

	_finalize_placement()


func _regrow_top() -> void:
	var grow: float = min(PERFECT_REGROW, start_width_eff - top_width)
	if grow <= 0.0:
		return
	var new_w: float = top_width + grow
	# Ortalı büyüt, ekran içinde kalacak şekilde kıstır.
	var new_left: float = clamp(top_x - grow * 0.5, 0.0, max(0.0, view_w - new_w))
	top_width = new_w
	top_x = new_left
	var top_block: ColorRect = blocks.back()
	top_block.position.x = new_left
	top_block.size.x = new_w


# ----------------------------------------------------------------------------
#  Kesimli yerleştirme
# ----------------------------------------------------------------------------
func _handle_cut(cur_x: float, cur_w: float) -> void:
	var a_left: float = cur_x
	var a_right: float = cur_x + cur_w

	var o_left: float = max(a_left, top_x)
	var o_right: float = min(a_right, top_x + top_width)
	var o_w: float = o_right - o_left

	# Çakışma yok veya kalan genişlik eşiğin altında -> OYUN BİTER.
	if o_w <= MIN_WIDTH:
		# Aktif bloğu küçük kalan halde göster, sonra biter.
		if o_w > 0.0:
			active_block.position.x = o_left
			active_block.size.x = o_w
		_game_over()
		return

	var col: Color = active_block.color
	var y: float = active_block.position.y

	# Taşan kısmı/kısımları düşen parça olarak ayır.
	if a_left < o_left:
		_spawn_falling(a_left, y, o_left - a_left, col)
	if a_right > o_right:
		_spawn_falling(o_right, y, a_right - o_right, col)

	# Aktif blok kesilmiş genişlikte yerine oturur.
	active_block.position.x = o_left
	active_block.size.x = o_w
	blocks.append(active_block)

	top_x = o_left
	top_width = o_w

	# Kesim olduğu için combo/perfect sıfırlanır.
	combo = 0
	perfect_streak = 0

	_finalize_placement()


func _spawn_falling(left: float, y: float, width: float, col: Color) -> void:
	var f := ColorRect.new()
	f.size = Vector2(width, BLOCK_HEIGHT)
	f.position = Vector2(left, y)
	f.color = col
	world.add_child(f)

	var t := create_tween()
	t.tween_property(f, "position:y", y + FALL_DISTANCE, FALL_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(f, "modulate:a", 0.0, FALL_TIME)
	t.tween_callback(f.queue_free)


# ----------------------------------------------------------------------------
#  Yerleştirme sonrası ortak işler
# ----------------------------------------------------------------------------
func _finalize_placement() -> void:
	score += 1
	speed = min(speed + SPEED_INC, MAX_SPEED)

	# Kuleyi yukarı kaydır (aktif blok hep aynı yükseklikte kalsın).
	var target_y: float = play_y + float(blocks.size()) * BLOCK_HEIGHT
	var t := create_tween()
	t.tween_property(world, "position:y", target_y, SCROLL_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_spawn_active()
	_update_hud()


# ----------------------------------------------------------------------------
#  Animasyon yardımcıları
# ----------------------------------------------------------------------------
func _flash_block(b: ColorRect) -> void:
	b.self_modulate = Color(1.8, 1.8, 1.8, 1.0)
	var t := create_tween()
	t.tween_property(b, "self_modulate", Color(1, 1, 1, 1), 0.30)


func _show_perfect_text() -> void:
	perfect_label.text = "Mükemmel x%d" % combo
	perfect_label.modulate = Color(1, 1, 1, 0)
	var t := create_tween()
	t.tween_property(perfect_label, "modulate:a", 1.0, 0.08)
	t.tween_interval(0.35)
	t.tween_property(perfect_label, "modulate:a", 0.0, 0.40)


# ============================================================================
#  OYUN BİTTİ
# ============================================================================
func _game_over() -> void:
	state = State.GAMEOVER
	var new_record: bool = SaveManager.update_best(score)

	go_score_label.text = "Skor: %d" % score
	go_best_label.text = "En İyi: %d" % SaveManager.best_score
	go_coins_label.text = "🪙 Kazanılan: %d" % run_coins
	go_record_label.visible = new_record

	_show_only(gameover_panel)


# ============================================================================
#  ARAYÜZ (UI) — tamamen kod içinde
# ============================================================================
func _build_ui() -> void:
	# --- Arka plan (kendi CanvasLayer'ında, en arkada) ---
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = _bg_color()
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg_rect)

	# --- UI katmanı (en önde) ---
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)

	_build_menu(ui_layer)
	_build_hud(ui_layer)
	_build_gameover(ui_layer)
	_build_shop(ui_layer)


# ----------------------------------------------------------------------------
#  Ortak UI fabrika fonksiyonları
# ----------------------------------------------------------------------------
func _new_panel(parent: Node) -> Control:
	var p := Control.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _new_label(text: String, size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _new_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 44)
	b.custom_minimum_size = Vector2(420, 110)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b


## Dikey ortalanmış içerik kabı (menü/gameover/shop için).
func _center_vbox(parent: Control, separation: int = 28) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", separation)
	v.offset_left = 60
	v.offset_right = -60
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)
	return v


# ----------------------------------------------------------------------------
#  MENÜ
# ----------------------------------------------------------------------------
func _build_menu(parent: Node) -> void:
	menu_panel = _new_panel(parent)
	var v := _center_vbox(menu_panel)

	v.add_child(_new_label("STACK", 130, Color(0.95, 0.95, 1.0)))
	v.add_child(_new_label("TOWER", 90, Color(0.7, 0.8, 1.0)))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	v.add_child(spacer)

	menu_best_label = _new_label("En İyi: 0", 46)
	v.add_child(menu_best_label)
	menu_coin_label = _new_label("🪙 0", 46, Color(1.0, 0.85, 0.3))
	v.add_child(menu_coin_label)
	menu_streak_label = _new_label("🔥 0 gün", 46, Color(1.0, 0.55, 0.3))
	v.add_child(menu_streak_label)
	menu_bonus_label = _new_label("", 38, Color(0.6, 1.0, 0.6))
	v.add_child(menu_bonus_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	v.add_child(spacer2)

	var start_btn := _new_button("BAŞLA")
	start_btn.pressed.connect(_start_game)
	v.add_child(start_btn)

	var shop_btn := _new_button("MAĞAZA")
	shop_btn.pressed.connect(_goto_shop)
	v.add_child(shop_btn)

	var hint := _new_label("(Başlamak için ekrana dokun / Space)", 30, Color(0.7, 0.7, 0.7))
	v.add_child(hint)


func _refresh_menu() -> void:
	menu_best_label.text = "En İyi: %d" % SaveManager.best_score
	menu_coin_label.text = "🪙 %d" % SaveManager.coins
	menu_streak_label.text = "🔥 %d gün" % SaveManager.streak_count
	menu_bonus_label.text = streak_bonus_msg


# ----------------------------------------------------------------------------
#  HUD (oyun içi)
# ----------------------------------------------------------------------------
func _build_hud(parent: Node) -> void:
	hud_panel = _new_panel(parent)

	# Üst bilgi çubuğu (skor solda-ortada, coin sağda).
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 40
	top.offset_left = 50
	top.offset_right = -50
	top.offset_bottom = 160
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_child(top)

	score_label = _new_label("0", 90)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(score_label)

	hud_coin_label = _new_label("🪙 0", 56, Color(1.0, 0.85, 0.3))
	hud_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(hud_coin_label)

	# Ortada beliren "Mükemmel" yazısı.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = -view_h * 0.18
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_child(center)

	perfect_label = _new_label("", 70, Color(1.0, 0.95, 0.4))
	perfect_label.modulate = Color(1, 1, 1, 0)
	center.add_child(perfect_label)


func _update_hud() -> void:
	score_label.text = str(score)
	hud_coin_label.text = "🪙 %d" % SaveManager.coins


# ----------------------------------------------------------------------------
#  OYUN BİTTİ ekranı
# ----------------------------------------------------------------------------
func _build_gameover(parent: Node) -> void:
	gameover_panel = _new_panel(parent)
	var v := _center_vbox(gameover_panel)

	v.add_child(_new_label("OYUN BİTTİ", 90, Color(1.0, 0.5, 0.5)))

	go_record_label = _new_label("🏆 YENİ REKOR!", 56, Color(1.0, 0.9, 0.3))
	go_record_label.visible = false
	v.add_child(go_record_label)

	go_score_label = _new_label("Skor: 0", 60)
	v.add_child(go_score_label)
	go_best_label = _new_label("En İyi: 0", 50)
	v.add_child(go_best_label)
	go_coins_label = _new_label("🪙 Kazanılan: 0", 50, Color(1.0, 0.85, 0.3))
	v.add_child(go_coins_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	v.add_child(spacer)

	var retry_btn := _new_button("TEKRAR")
	retry_btn.pressed.connect(_start_game)
	v.add_child(retry_btn)

	var menu_btn := _new_button("MENÜ")
	menu_btn.pressed.connect(_goto_menu)
	v.add_child(menu_btn)


# ----------------------------------------------------------------------------
#  MAĞAZA
# ----------------------------------------------------------------------------
func _build_shop(parent: Node) -> void:
	shop_panel = _new_panel(parent)
	var v := _center_vbox(shop_panel, 22)

	v.add_child(_new_label("MAĞAZA", 80, Color(0.8, 0.9, 1.0)))

	shop_coin_label = _new_label("🪙 0", 50, Color(1.0, 0.85, 0.3))
	v.add_child(shop_coin_label)

	# Palet satırlarının ekleneceği liste.
	shop_list = VBoxContainer.new()
	shop_list.add_theme_constant_override("separation", 16)
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(shop_list)

	var back_btn := _new_button("GERİ")
	back_btn.pressed.connect(_goto_menu)
	v.add_child(back_btn)


func _refresh_shop() -> void:
	shop_coin_label.text = "🪙 %d" % SaveManager.coins

	# Listeyi temizle ve baştan kur (kilit/seçim durumunu yansıtmak için).
	for c in shop_list.get_children():
		c.queue_free()

	for i in range(PALETTES.size()):
		shop_list.add_child(_make_shop_row(i))


func _make_shop_row(idx: int) -> Control:
	var pal: Dictionary = PALETTES[idx]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Renk önizleme (paletin temel tonu).
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(80, 80)
	swatch.color = Color.from_hsv(float(pal["hue"]), BLOCK_SAT, BLOCK_VAL)
	row.add_child(swatch)

	# İsim + durum
	var name_label := _new_label(str(pal["name"]), 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var unlocked: bool = SaveManager.is_unlocked(idx)
	var selected: bool = (SaveManager.selected_palette == idx)
	var price: int = int(pal["price"])

	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 36)
	btn.custom_minimum_size = Vector2(220, 80)

	if not unlocked:
		btn.text = "Aç (🪙%d)" % price
		btn.disabled = SaveManager.coins < price
		btn.pressed.connect(_on_shop_unlock.bind(idx, price))
	elif selected:
		btn.text = "✔ Seçili"
		btn.disabled = true
	else:
		btn.text = "Seç"
		btn.pressed.connect(_on_shop_select.bind(idx))

	row.add_child(btn)
	return row


func _on_shop_unlock(idx: int, price: int) -> void:
	if SaveManager.try_unlock(idx, price):
		SaveManager.select_palette(idx)  # açınca otomatik seç
		_apply_palette()
	_refresh_shop()


func _on_shop_select(idx: int) -> void:
	SaveManager.select_palette(idx)
	_apply_palette()
	_refresh_shop()


func _apply_palette() -> void:
	bg_rect.color = _bg_color()


# ============================================================================
#  EKRAN GEÇİŞLERİ
# ============================================================================
func _show_only(panel: Control) -> void:
	menu_panel.visible = (panel == menu_panel)
	hud_panel.visible = (panel == hud_panel)
	gameover_panel.visible = (panel == gameover_panel)
	shop_panel.visible = (panel == shop_panel)


func _goto_menu() -> void:
	state = State.MENU
	_clear_world()
	_apply_palette()
	_refresh_menu()
	_show_only(menu_panel)


func _goto_shop() -> void:
	state = State.SHOP
	_refresh_shop()
	_show_only(shop_panel)
