extends RefCounted
## Единая палитра ClipStar (8 цветов). Её используют материалы студии, тема UI и иконки (assets/icons/*.svg).

const INK: Color = Color("2b1e3f")     # обводка, тени, текст на светлом
const PLUM: Color = Color("5b3f8c")    # волосы, пол, тёмные пропсы
const LAVENDER: Color = Color("a78bfa") # мебель, акценты
const PINK: Color = Color("ff6b9a")    # одежда Миры, кнопки, неон
const PEACH: Color = Color("ffc9a8")   # кожа
const SUN: Color = Color("ffd166")     # монеты, лампы, награды
const MINT: Color = Color("4fd1a5")    # ковёр, растения, прогресс
const CREAM: Color = Color("fff4e6")   # стол, белки глаз, блики

const ALL: Dictionary = {
	"ink": INK, "plum": PLUM, "lavender": LAVENDER, "pink": PINK,
	"peach": PEACH, "sun": SUN, "mint": MINT, "cream": CREAM,
}
