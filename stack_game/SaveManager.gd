extends Node
## SaveManager — Autoload (singleton).
## user://save.json içine kalıcı verileri yazar/okur.
## JSON okuma/yazma hataları güvenli ele alınır (dosya yoksa varsayılan üretilir).

const SAVE_PATH: String = "user://save.json"

# Streak (günlük seri) ayarları
const STREAK_BONUS_PER_DAY: int = 5
const STREAK_BONUS_MAX: int = 100

# --- Kalıcı veri alanları ---
var best_score: int = 0
var coins: int = 0
var unlocked_palettes: Array = [0]   # açık palet indeksleri
var selected_palette: int = 0
var last_play_date: String = ""      # ISO tarih: "YYYY-MM-DD"
var streak_count: int = 0


func _ready() -> void:
	load_game()


# ----------------------------------------------------------------------------
#  Varsayılan veri
# ----------------------------------------------------------------------------
func _default_data() -> Dictionary:
	return {
		"best_score": 0,
		"coins": 0,
		"unlocked_palettes": [0],
		"selected_palette": 0,
		"last_play_date": "",
		"streak_count": 0,
	}


# ----------------------------------------------------------------------------
#  Yükleme
# ----------------------------------------------------------------------------
func load_game() -> void:
	# Dosya yoksa varsayılan oluştur ve kaydet.
	if not FileAccess.file_exists(SAVE_PATH):
		_apply(_default_data())
		save_game()
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		# Açılamadı -> güvenli varsayılan.
		_apply(_default_data())
		return

	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		# Bozuk JSON -> varsayılana dön ve düzelt.
		_apply(_default_data())
		save_game()
		return

	_apply(parsed as Dictionary)


func _apply(d: Dictionary) -> void:
	best_score = int(d.get("best_score", 0))
	coins = int(d.get("coins", 0))

	# unlocked_palettes güvenli dönüşüm
	unlocked_palettes = []
	var up: Variant = d.get("unlocked_palettes", [0])
	if typeof(up) == TYPE_ARRAY:
		for v in up:
			var iv: int = int(v)
			if not unlocked_palettes.has(iv):
				unlocked_palettes.append(iv)
	if unlocked_palettes.is_empty():
		unlocked_palettes = [0]

	selected_palette = int(d.get("selected_palette", 0))
	if not unlocked_palettes.has(selected_palette):
		selected_palette = 0

	last_play_date = str(d.get("last_play_date", ""))
	streak_count = int(d.get("streak_count", 0))


# ----------------------------------------------------------------------------
#  Kaydetme
# ----------------------------------------------------------------------------
func save_game() -> void:
	var d := {
		"best_score": best_score,
		"coins": coins,
		"unlocked_palettes": unlocked_palettes,
		"selected_palette": selected_palette,
		"last_play_date": last_play_date,
		"streak_count": streak_count,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		# Yazılamadıysa sessizce geç (oyun çökmemeli).
		return
	f.store_string(JSON.stringify(d, "\t"))
	f.close()


# ----------------------------------------------------------------------------
#  Coin / palet / skor yardımcıları
# ----------------------------------------------------------------------------
func add_coins(n: int) -> void:
	coins += n
	if coins < 0:
		coins = 0
	save_game()


func is_unlocked(idx: int) -> bool:
	return unlocked_palettes.has(idx)


## Palet açmayı dener. Başarılıysa true döner.
func try_unlock(idx: int, price: int) -> bool:
	if is_unlocked(idx):
		return false
	if coins < price:
		return false
	coins -= price
	unlocked_palettes.append(idx)
	save_game()
	return true


func select_palette(idx: int) -> void:
	if is_unlocked(idx):
		selected_palette = idx
		save_game()


## Yeni rekorsa best_score'u günceller ve true döner.
func update_best(s: int) -> bool:
	if s > best_score:
		best_score = s
		save_game()
		return true
	return false


# ----------------------------------------------------------------------------
#  Günlük seri (streak)
# ----------------------------------------------------------------------------
## Oyun açılışında bir kez çağrılır.
## Dönüş: { "new_day": bool, "bonus": int } — bugün ilk açılışsa bonus verilir.
func update_streak() -> Dictionary:
	var today: String = Time.get_date_string_from_system()  # "YYYY-MM-DD"

	# Bugün zaten oynanmış: değişiklik yok, bonus yok.
	if last_play_date == today:
		return {"new_day": false, "bonus": 0}

	if last_play_date == "":
		# İlk kez oynuyor.
		streak_count = 1
	else:
		var diff_days: int = _day_difference(last_play_date, today)
		if diff_days == 1:
			streak_count += 1        # dün oynamış -> seri devam
		else:
			streak_count = 1         # daha eski / geçersiz -> sıfırla

	last_play_date = today

	# Seriye göre küçük coin bonusu (streak * 5, max 100).
	var bonus: int = min(streak_count * STREAK_BONUS_PER_DAY, STREAK_BONUS_MAX)
	coins += bonus
	save_game()
	return {"new_day": true, "bonus": bonus}


## İki ISO tarih ("YYYY-MM-DD") arasındaki gün farkı (b - a).
func _day_difference(a: String, b: String) -> int:
	var ua: float = Time.get_unix_time_from_datetime_string(a + "T00:00:00")
	var ub: float = Time.get_unix_time_from_datetime_string(b + "T00:00:00")
	return int(round((ub - ua) / 86400.0))
