<%@ page contentType="text/html; charset=windows-1251" language="java" pageEncoding="windows-1251" %>
<!DOCTYPE html>

<html lang="ru">
<head>
    <meta charset="windows-1251" />
    <title>Данные с бэкенда</title>
</head>
<body>
<h1>Строки из бэкенда</h1>
<ul id="lines"></ul>

<script>
    // Делает запрос к серверу и отображает строки
    fetch('/modules.anttest/data')
        .then(response => response.blob())
        .then(blob => blob.arrayBuffer()
            .then(buffer => {
                const decoder = new TextDecoder('windows-1251');
                const text = decoder.decode(buffer);
                return text;
            })
        )
        .then(text => {
            const data = JSON.parse(text);
            const list = document.getElementById('lines');
            data.forEach(line => {
                const li = document.createElement('li');
                li.textContent = line;
                list.appendChild(li);
            });
        })
        .catch(error => {
            console.error('Ошибка получения данных:', error);
        });
</script>
</body>
</html>