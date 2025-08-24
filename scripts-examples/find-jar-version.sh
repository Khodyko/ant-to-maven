#!/bin/bash

# Функция для отображения справки
show_help() {
  echo "Использование: bash find-jar-version.sh <путь_к_папке> [имя_файла_для_записи]"
  echo
  echo "Параметры:"
  echo "  <путь_к_папке>       Путь к папке, содержащей JAR файлы."
  echo "  [имя_файла_для_записи]  (Опционально) Файл, в который будет записан вывод скрипта."
  echo
  echo "Описание:"
  echo "  Скрипт обходит все JAR файлы в указанной папке и извлекает информацию из их манифестов,"
  echo "  а также из файлов pom.properties и pom.xml, если они присутствуют."
  echo
  echo "Примеры:"
  echo "  bash find-jar-version.sh /path/to/folder"
  echo "  bash find-jar-version.sh /path/to/folder output.txt"
  echo
  echo "Обратите внимание:"
  echo "  Убедитесь, что у вас установлены необходимые инструменты для работы с JAR файлами (например, unzip)."
}

# Проверка количества аргументов
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Использование: bash find-jar-version.sh <путь_к_папке> [имя_файла_для_записи]"
  exit 1
fi

folder="$1"
output_file="$2"

# Проверка существования папки
if [ ! -d "$folder" ]; then
  echo "Папка не найдена: $folder"
  exit 1
fi

# Если файл для записи указан, открыть его для записи
if [ -n "$output_file" ]; then
  exec > >(tee -a "$output_file") 2>&1
fi

# Обход всех jar файлов в папке
for jar in "$folder"/*.jar; do
  if [ -f "$jar" ]; then
    echo "Обработка файла: $jar"
    
    # Название jar файла
    echo "Название файла: $(basename "$jar")"
    
    # Попытка извлечь MANIFEST.MF только из META-INF/
    manifest=$(unzip -p "$jar" META-INF/MANIFEST.MF 2>/dev/null)
    if [ $? -eq 0 ]; then
      echo "Содержимое MANIFEST.MF:"
      echo "$manifest"
      
      # Поиск строки Class-Path
      class_path=$(echo "$manifest" | grep -i "^Class-Path:")
      if [ -n "$class_path" ]; then
        echo "Зависимости:"
        dependencies=$(echo "$class_path" | sed 's/^Class-Path:\s*//' )
        for dep in $dependencies; do
          echo "  $dep"
        done
      else
        echo "Зависимости (Class-Path) не найдены."
      fi
    else
      echo "MANIFEST.MF в корневой папке META-INF/ не найден или не может быть прочитан."
    fi

    # Попытка найти и вывести pom.properties
    pom_properties=$(unzip -p "$jar" "META-INF/maven/*/*/pom.properties" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$pom_properties" ]; then
      echo "Содержимое pom.properties:"
      echo "$pom_properties"
    else
      echo "pom.properties не найден."
    fi

    # Попытка найти и обработать pom.xml
    pom_xml=$(unzip -p "$jar" "META-INF/maven/*/*/pom.xml" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$pom_xml" ]; then
      echo "groupId:"
      echo "$pom_xml" | grep -m 1 "<groupId>" | sed -n 's/.*<groupId>\(.*\)<\/groupId>.*/\1/p'
      
      echo "artifactId:"
      echo "$pom_xml" | grep -m 1 "<artifactId>" | sed -n 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/p'
      
      echo "version:"
      echo "$pom_xml" | grep -m 1 "<version>" | sed -n 's/.*<version>\(.*\)<\/version>.*/\1/p'
    else
      echo "pom.xml не найден."
    fi

    echo "-----------------------------"
  fi
done