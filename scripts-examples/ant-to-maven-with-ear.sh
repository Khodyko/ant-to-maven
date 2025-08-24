#!/bin/bash

# Функция для отображения помощи
show_help() {
  echo "Использование: $0 <путь_к_структуре_Maven> <путь_к_ant_папке> <artifactId_родителя> [empty]"
  echo
  echo "Описание:"
  echo "Этот скрипт создаёт структуру Maven для проекта, преобразуя папки ant в модули Maven."
  echo "Для каждого модуля имя artifactId формируется из имени папки и типа."
  echo "Если последний аргумент равен 'empty', то artifactId — просто имя папки без постфикса."
  echo "Он создаст папки с src/main/java, src/main/resources, src/main/webapp (для web), и файлы pom.xml."
  echo "Главный pom.xml не создаётся."
  echo "Также копируется содержимое исходных src из папок ant в новые модули."
  echo
  echo "Аргументы:"
  echo "  <путь_к_структуре_Maven> - путь, куда будет создана структура Maven"
  echo "  <путь_к_ant_папке> - путь к папке ant, внутри которой есть папка 'projects'"
  echo "  <artifactId_родителя> - имя artifactId для модулей"
  echo "  [empty] - опционально, если указано, artifactId не будет содержать постфикс"
  echo
  echo "Пример:"
  echo "  $0 /home/user/maven_project /home/user/ant_project my-parent-artifact"
  echo "  $0 /home/user/maven_project /home/user/ant_project my-parent-artifact empty"
}

SEPAR="_"
MAIN_POM_GROUP_ID="khodyko-modules"
MAIN_POM_ARTIFACT_ID="anttest"

# Проверка на вызов помощи
if [ "$#" -eq 1 ] && ( [ "$1" = "-h" ] || [ "$1" = "--help" ] ); then
  show_help
  exit 0
fi

# Проверка количества аргументов
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Ошибка: неверное число аргументов."
  echo "Для получения помощи вызовите:"
  echo "  $0 --help"
  exit 1
fi

TARGET_DIR="$1"
ANT_DIR="$2"
PARENT_ARTIFACT_ID="$3"
EMPTY_MODE="$4"  # может быть 'empty' или пустой

# Получаем имя последней папки в TARGET_DIR (для обертки вокруг модулей)
base_folder_name=$(basename "$ANT_DIR")

# Создаем целевую папку
mkdir -p "$TARGET_DIR"

# Находим папку projects внутри ant
PROJECTS_DIR=$(find "$ANT_DIR" -type d -name "projects" | head -n 1)
if [ -z "$PROJECTS_DIR" ]; then
  echo "Папка projects не найдена внутри $ANT_DIR"
  exit 1
fi

# Получаем префикс для artifactId
get_parent_prefix() {
  local empty_mode=$1
  if [ "$empty_mode" = "empty" ]; then
    echo ""
  else
    echo "$PARENT_ARTIFACT_ID"
  fi
}
parent_prefix="$(get_parent_prefix "$EMPTY_MODE")"

# Создаем папку-обертку
OBERON_DIR="$TARGET_DIR/$base_folder_name"
mkdir -p "$OBERON_DIR"

# Создаем главный pom.xml для обертки (родительский проект)
cat > "$OBERON_DIR/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>${MAIN_POM_GROUP_ID}</groupId>
    <artifactId>${MAIN_POM_ARTIFACT_ID}</artifactId>
    <version>1.0-SNAPSHOT</version>
    <relativePath>../pom.xml</relativePath>
  </parent>
  <artifactId>${parent_prefix}${SEPAR}${base_folder_name}</artifactId>
  <packaging>pom</packaging>
  <modules>
EOF

# Массив для хранения имён модулей
declare -a MODULE_NAMES=()

# Перебираем папки внутри projects
for module_path in "$PROJECTS_DIR"/*; do
  if [ -d "$module_path" ]; then
    module_name=$(basename "$module_path")
    # Определяем тип модуля по имени папки
    case "$module_name" in
      "ejb") postfix="ejb" ;;
      "lib") postfix="lib" ;;
      "web") postfix="web" ;;
      *) 
        # пропускаем остальные
        continue
        ;;
    esac

    # Имя папки модуля
    last_folder_name="$base_folder_name"

    # Формируем artifactId
    artifact_id="${parent_prefix}${SEPAR}${last_folder_name}${SEPAR}${postfix}"

    # Создаем папку модуля внутри обертки
    module_dir="$OBERON_DIR/$base_folder_name$SEPAR$postfix"
    mkdir -p "$module_dir/src/main/java"
    mkdir -p "$module_dir/src/main/resources"
    if [ "$postfix" = "web" ]; then
      mkdir -p "$module_dir/src/main/webapp"
    fi

    # Пути исходных данных
    src_dir="$PROJECTS_DIR/$module_name/src"
    web_root_dir="$PROJECTS_DIR/$module_name/WebRoot"

    # Создаем pom.xml для модуля
    dependencies=""
    packaging="jar"

    if [ "$postfix" = "ejb" ]; then
      META_INF_SRC="$src_dir/META-INF"
      META_INF_DEST="$module_dir/src/main/resources/META-INF"
      if [ -d "$META_INF_SRC" ]; then
        mkdir -p "$META_INF_DEST"
        cp -r "$META_INF_SRC/"* "$META_INF_DEST"/
      fi
    fi

    if [ "$postfix" = "lib" ]; then
      packaging="jar"
      dependencies=$(cat <<EOF
      
EOF
      )
    fi

    if [ "$postfix" = "web" ]; then
      packaging="war"
dependencies=$(cat <<EOF
    
EOF
      )
    fi

    if [ "$postfix" = "ejb" ]; then
      packaging="ejb"
      dependencies=$(cat <<EOF
          
EOF
      )
    fi


    # Создаём pom.xml модуля
    cat > "$module_dir/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>${MAIN_POM_GROUP_ID}</groupId>
    <artifactId>${parent_prefix}${SEPAR}${base_folder_name}</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>
  <artifactId>$artifact_id</artifactId>
  <packaging>$packaging</packaging>
  <dependencies>
    $dependencies
  </dependencies>
</project>
EOF

    echo "Обрабатываем модуль: $module_name, тип: $postfix"
    echo "Создана папка: $module_dir"

    # Копируем исходники
    if [ -d "$src_dir" ]; then
      rsync -a --exclude='META-INF' "$src_dir/" "$module_dir/src/main/java/"
      # Для web - копируем WebRoot
      if [ "$postfix" = "web" ] && [ -d "$web_root_dir" ]; then
        mkdir -p "$module_dir/src/main/webapp"
        rsync -a "$web_root_dir/" "$module_dir/src/main/webapp/"
      fi
    fi

    # Добавляем имя модуля в список для parent pom.xml
    MODULE_NAMES+=("$base_folder_name$SEPAR$postfix")
  fi
done

# Заканчиваем parent pom.xml
for module_name in "${MODULE_NAMES[@]}"; do
  echo "    <module>$module_name</module>" >> "$OBERON_DIR/pom.xml"
done
echo "    <module>$base_folder_name$SEPAR"ear"</module>" >> "$OBERON_DIR/pom.xml"
echo "  </modules>" >> "$OBERON_DIR/pom.xml"
echo "</project>" >> "$OBERON_DIR/pom.xml"

# Создаем модуль EAR
EAR_MODULE_DIR="$OBERON_DIR/$base_folder_name${SEPAR}ear"
mkdir -p "$EAR_MODULE_DIR"

# Перед созданием ear/pom.xml
DEPENDENCIES_EAR=""
for mod in "${MODULE_NAMES[@]}"; do
  # Определяем тип по postfix в имени модуля
  if [[ "$mod" == *"web" ]]; then
    module_type="war"
  elif [[ "$mod" == *"ejb" ]]; then
    module_type="ejb"
  elif [[ "$mod" == *"lib" ]]; then
    module_type="jar"
  else
    module_type="jar"  # по умолчанию
  fi

  DEPENDENCIES_EAR+="
    <dependency>
      <groupId>${MAIN_POM_GROUP_ID}</groupId>
      <artifactId>${parent_prefix}$SEPAR$mod</artifactId>
      <version>\${project.version}</version>
      <type>$module_type</type>
    </dependency>"
done

# Создаем pom.xml для EAR
cat > "$EAR_MODULE_DIR/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
   <parent>
    <groupId>${MAIN_POM_GROUP_ID}</groupId>
    <artifactId>${parent_prefix}$SEPAR${base_folder_name}</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>
  <artifactId>${parent_prefix}$SEPAR${base_folder_name}${SEPAR}ear</artifactId>
  <packaging>ear</packaging>
  
  <dependencies>${DEPENDENCIES_EAR}
  </dependencies>
</project>
EOF


echo "Создан модуль EAR: $EAR_MODULE_DIR"

echo "Структура Maven успешно создана в $TARGET_DIR"