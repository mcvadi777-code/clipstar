# ClipStar — сборка APK в GitHub Actions (без ПК и без Unity)

## Что нужно от проекта (требования к репозиторию)
- Движок: **Godot 4.3** (бесплатный, без лицензий, экспорт APK работает в CI).
- В корне репозитория: `project.godot`, `export_presets.cfg`, папки `scenes/`, `scripts/`, `assets/`.
- В `export_presets.cfg` должен быть пресет с именем **Android** (экспорт Android, пакет `com.clipstar.game`).
- В `project.godot` главная сцена (main scene) задана, все ресурсы только внутри `res://`.
- `.gitignore`: игнорировать `.godot/`, `build/`, `.import/`; **не** игнорировать `.import` файлы? — нет:
  импортируемые файлы и их `.import` можно отдавать, Godot пересоберёт кэш сам.
- Никаких плагинов, требующих платной лицензии или закрытых SDK.

## Шаги (делается с телефона в браузере)
1. Создать репозиторий на github.com (Public или Private), залить проект + файл
   `.github/workflows/build-apk.yml` (уже готов в этой папке).
2. Открыть вкладку **Actions** → workflow **build-apk** → кнопка **Run workflow**.
3. Подождать ~5–10 минут. Зелёная галочка = APK собран.
4. Зайти в завершённый запуск → внизу раздел **Artifacts** → скачать `ClipStar-apk`
   (это zip, внутри `ClipStar.apk`).
5. Установить APK на телефон: разрешить установку из неизвестных источников.
6. Если шаг «Экспорт APK» упал — открыть лог, скопировать ошибку и прислать разработчику.

## Частые ошибки и лечение
- `No export template found` — версия Godot в проекте не 4.3. Поставить 4.3 в `project.godot`
  (`config/features=PackedStringArray("4.3", "GL Compatibility")`) или поменять тег образа в workflow.
- `Export preset "Android" not found` — пресет называется иначе; переименовать в `Android`.
- `Android SDK path is not configured` — экспортный пресет должен быть Android, не Web/Windows.
- `Missing keystore` — добавить шаг создания debug.keystore (он уже в workflow).
- `Nothing to export` — в проект не добавлена главная сцена.

## Ротация ключей и подпись для Google Play (позже)
Для беты достаточно debug-APK. Для Play Console нужен release-keystore:
сгенерировать `keytool -genkeypair`, залить base64 в Secrets `ANDROID_KEYSTORE_BASE64`,
добавить в workflow декодирование и шаг `--export-release`. Скажи — подготовлю отдельный workflow.
