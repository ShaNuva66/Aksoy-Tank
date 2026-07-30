# Kaynak Kod

Bu klasor, Godot tabanli oyun kodunu ve sahnelerini icermek icin hazirlandi.

- `scenes/`: Godot sahneleri
- `scripts/`: oyun mantigi

Ilk prototip dosyalari olusturuldu:

- `scenes/main_menu.tscn`
- `scenes/prototype_arena.tscn`
- `scenes/player_tank.tscn`
- `scenes/enemy_tank.tscn`
- `scenes/bullet.tscn`
- `scenes/wall_block.tscn`
- `scenes/mobile_controls.tscn`

Kampanya altyapisi da eklendi:

- `scripts/stage_catalog.gd`: 10 stage veri katalogu
- `scripts/game_session.gd`: secili stage ve campaign oturumu
- `scripts/virtual_joystick.gd`: mobil sanal joystick davranisi

Kayit ilerlemesi `user://campaign_progress.cfg` altina yazilir.
