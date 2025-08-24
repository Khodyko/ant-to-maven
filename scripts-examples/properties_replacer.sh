#!/bin/bash

# Функция для отображения помощи
show_help() {
  echo "Использование: $0 <путь_к_properties_файлу> <путь_к_файлу_или_папке>"
  echo
  echo "Описание:"
  echo "Этот скрипт читает файл .properties и заменяет в указанных файлах или папках все вхождения"
  echo "шаблонов @{имя} или \${имя} на соответствующие значения из файла свойств."
  echo
  echo "Параметры:"
  echo "  <путь_к_properties_файлу>  - путь к файлу .properties с ключами и значениями"
  echo "  <путь_к_файлу_или_папке> - файл или папка, в которых нужно выполнить замену"
  echo
  echo "Пример:"
  echo "  $0 ./config.properties ./project"
  echo
  echo "Если параметры не указаны или неправильные, выводится это сообщение."
}

# Проверка на флаг --help или -h
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# Проверка аргументов
if [ "$#" -ne 2 ]; then
  echo "Ошибка: неверное количество аргументов."
  show_help
  exit 1
fi

PROPS_FILE="$1"
TARGET_PATH="$2"

# Проверка существования файла свойств
if [ ! -f "$PROPS_FILE" ]; then
  echo "Файл свойств не найден: $PROPS_FILE"
  exit 1
fi

# Проверка существования папки или файла для поиска
if [ ! -e "$TARGET_PATH" ]; then
  echo "Целевой путь не найден: $TARGET_PATH"
  exit 1
fi

# Чтение ключей и значений из файла свойств
declare -A props

echo "Читаем файл свойств: $PROPS_FILE"
# Чтение файла свойств
declare -A props
while IFS='=' read -r key value; do
  if [[ "$key" =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
    continue
  fi
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  props["$key"]="$value"
done < "$PROPS_FILE"

# Функция замены
replace_in_file() {
  local file="$1"
  echo "Обрабатываю файл: $file"
  for key in "${!props[@]}"; do
    local value="${props[$key]}"
    echo "  Замена: \${$key} и @{$key} на '$value'"
    sed -i "s|\${$key}|$value|g" "$file"
    sed -i "s|@{$key}|$value|g" "$file"
  done
}

# Обработка файлов
if [ -d "$TARGET_PATH" ]; then
  find "$TARGET_PATH" -type f -print0 | while IFS= read -r -d $'\0' file; do
    replace_in_file "$file"
  done
elif [ -f "$TARGET_PATH" ]; then
  replace_in_file "$TARGET_PATH"
else
  echo "Целевой путь не является файлом или папкой."
  exit 1
fi

echo "Завершено."