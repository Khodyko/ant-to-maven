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

# Выясняем, последний компонент пути (имя папки)
# Для этого возьмём basename последней папки в пути
# например, /path/to/folder — возьмём "folder"
# Для этого используем команду basename
# Но важно, что путь может быть с или без слэша на конце
base_folder_name=$(basename "$TARGET_DIR")
# Для получения имени папки в ant, возьмём последний компонент
# внутри каждого модуля: basename "$module_name"

# Переходим в целевую директорию
mkdir -p "$TARGET_DIR"

# Находим папку projects внутри ant
PROJECTS_DIR=$(find "$ANT_DIR" -type d -name "projects" | head -n 1)

if [ -z "$PROJECTS_DIR" ]; then
  echo "Папка projects не найдена внутри $ANT_DIR"
  exit 1
fi

# Вспомогательная функция для создания pom.xml
create_pom() {
  local module_dir=$1
  local artifact_id=$2
  local dependencies=$3
  local packaging=$4

  cat > "$module_dir/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>khodyko-modules</groupId>
    <artifactId>$PARENT_ARTIFACT_ID</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>

  <artifactId>$artifact_id</artifactId>
  <packaging>$packaging</packaging>

  <dependencies>
    $dependencies
  </dependencies>
</project>
EOF
}

# формируем префикс
get_parent_prefix() {
  local empty_mode=$1
  if [ "$empty_mode" = "empty" ]; then
    echo ""
  else
    echo "$PARENT_ARTIFACT_ID-"
  fi
}

# Получаем имя целевой папки
target_base_name=$(basename "$ANT_DIR")
parent_prefix="$(get_parent_prefix "$EMPTY_MODE")"


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
        # Если папка не одна из нужных, пропускаем
        continue
        ;;
    esac

    # Имя папки последняя часть пути
    last_folder_name="$target_base_name"

    # Формируем artifactId
  
    artifact_id="${parent_prefix}${last_folder_name}-${postfix}"
    module_folder_name="${last_folder_name}-${postfix}"
  

    # Создаём структуру папок
    module_dir="$TARGET_DIR/$module_folder_name"
    mkdir -p "$module_dir/src/main/java"
    mkdir -p "$module_dir/src/main/resources"
    if [ "$postfix" = "web" ]; then
      mkdir -p "$module_dir/src/main/webapp"
    fi

    # Путь к src внутри проекта в projects
    src_dir="$PROJECTS_DIR/$module_name/src"
    web_root_dir="$PROJECTS_DIR/$module_name/WebRoot"


    # Создаём pom.xml
    dependencies=""
    packaging="jar"
   
    if [ "$postfix" = "ejb" ]; then
      # копируем META-INF
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
    <dependency>
      <groupId>javax</groupId>
      <artifactId>javaee-web-api</artifactId>
    </dependency>
    <dependency>
      <groupId>commons-httpclient</groupId>
      <artifactId>commons-httpclient</artifactId>
    </dependency>
EOF
      )
    fi

    if [ "$postfix" = "ejb" ]; then
      packaging="ejb"
    dependencies=$(cat <<EOF
            <dependency>
                <groupId>commons-lang</groupId>
                <artifactId>commons-lang</artifactId>
            </dependency>
            <dependency>
                <groupId>log4j</groupId>
                <artifactId>log4j</artifactId>
            </dependency>
            <dependency>
                <groupId>javax</groupId>
                <artifactId>javaee-web-api</artifactId>
            </dependency>
EOF
      )
    fi

    create_pom "$module_dir" "$artifact_id" "$dependencies" "$packaging"

    echo "src_dir $src_dir" 
    echo "$module_dir/src/main/java/"

    if [ -d "$src_dir" ]; then
      # Копируем main/java (всё содержимое)
      if [ -d "$src_dir/" ]; then
        rsync -a --exclude='META-INF' "$src_dir/" "$module_dir/src/main/java/"
      fi

      # Для web-модулей - копируем WebRoot
      if [ "$postfix" = "web" ] && [ -d "$web_root_dir" ]; then
        mkdir -p "$module_dir/src/main/webapp"
        rsync -a "$web_root_dir/" "$module_dir/src/main/webapp/"
      fi
    fi
  fi 
done

echo "Структура Maven создана в $TARGET_DIR"