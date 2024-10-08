# Параметры
$baseDir = "C:\RandomFiles" # Основная директория для хранения
$numberOfDirs = 5 # Количество создаваемых директорий
$filesPerDir = 3 # Количество файлов в каждой директории
$reportFilePath = Join-Path -Path $baseDir -ChildPath "report.txt" # Путь к отчету

# Создаём основную директорию, если она не существует
if (-Not (Test-Path $baseDir)) {
    New-Item -ItemType Directory -Path $baseDir
}

# Удаляем старый отчет, если он существует
if (Test-Path $reportFilePath) {
    Remove-Item $reportFilePath
}

# Функция для получения случайной статьи с Википедии
function Get-RandomWikipediaArticle {
    $url = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&format=json"
    $response = Invoke-RestMethod -Uri $url
    $pageId = $response.query.random[0].id

    # Получаем текст статьи
    $contentUrl = "https://en.wikipedia.org/w/api.php?action=parse&pageid=$pageId&prop=text&format=json"
    $contentResponse = Invoke-RestMethod -Uri $contentUrl
    return $contentResponse.parse.text['*'] -replace '<[^>]+>', '' # Убираем HTML-теги
}

# Функция для получения изображения из случайной статьи
function Get-RandomWikipediaImage {
    $url = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&format=json"
    $response = Invoke-RestMethod -Uri $url
    $pageId = $response.query.random[0].id

    # Получаем информацию о статье, чтобы найти изображение
    $imageUrl = "https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&pageids=$pageId"
    $imageResponse = Invoke-RestMethod -Uri $imageUrl

    # Проверяем, есть ли изображение
    if ($imageResponse.query.$pageId.pageimage) {
        $imageName = $imageResponse.query.$pageId.pageimage
        $imageFileUrl = "https://en.wikipedia.org/wiki/Special:FilePath/$imageName"

        # Скачиваем изображение
        $imagePath = Join-Path -Path $baseDir -ChildPath $imageName
        Invoke-WebRequest -Uri $imageFileUrl -OutFile $imagePath
        return $imagePath
    } else {
        return $null
    }
}

# Генерируем директории и файлы
for ($i = 0; $i -lt $numberOfDirs; $i++) {
    $dirName = "Тема_" + ($i + 1)
    $dirPath = Join-Path -Path $baseDir -ChildPath $dirName
    New-Item -ItemType Directory -Path $dirPath

    # Записываем в отчет имя созданной директории
    Add-Content -Path $reportFilePath -Value "Создана директория: $dirPath"

    for ($j = 0; $j -lt $filesPerDir; $j++) {
        $fileType = Get-Random -InputObject @('txt', 'docx', 'jpg')
        $fileName = "Документ_Тема_${i + 1}_Файл_${j + 1}.$fileType"
        $filePath = Join-Path -Path $dirPath -ChildPath $fileName

        switch ($fileType) {
            'txt' {
                $articleText = Get-RandomWikipediaArticle
                Set-Content -Path $filePath -Value $articleText
                Add-Content -Path $reportFilePath -Value "Создан файл: $filePath"
            }
            'docx' {
                $articleText = Get-RandomWikipediaArticle
                # Создаём документ Word
                $word = New-Object -ComObject Word.Application
                $doc = $word.Documents.Add()
                $doc.Content.Text = $articleText
                $doc.SaveAs([ref] $filePath)
                $doc.Close()
                $word.Quit()
                Add-Content -Path $reportFilePath -Value "Создан файл: $filePath"
            }
            'jpg' {
                $imagePath = Get-RandomWikipediaImage
                if ($imagePath) {
                    Copy-Item -Path $imagePath -Destination $filePath
                    Add-Content -Path $reportFilePath -Value "Создан файл: $filePath"
                } else {
                    # Если изображение не найдено, создаём пустое изображение
                    $image = New-Object Drawing.Bitmap 100, 100
                    $graphics = [Drawing.Graphics]::FromImage($image)
                    $graphics.Clear([Drawing.Color]::White)
                    $image.Save($filePath, [Drawing.Imaging.ImageFormat]::Jpeg)
                    $image.Dispose()
                    Add-Content -Path $reportFilePath -Value "Создан пустой файл: $filePath"
                }
            }
        }
    }
}

# Завершаем скрипт сообщением
Write-Host "Создание файлов завершено. Отчет сохранён в $reportFilePath"
