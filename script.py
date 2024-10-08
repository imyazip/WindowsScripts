import requests
import os
import random
from docx import Document
from bs4 import BeautifulSoup

def get_random_article():
    url = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&format=json"
    response = requests.get(url).json()
    page_id = response['query']['random'][0]['id']

    content_url = f"https://en.wikipedia.org/w/api.php?action=parse&pageid={page_id}&prop=text&format=json"
    content_response = requests.get(content_url).json()
    text = content_response['parse']['text']['*']

    # Убираем HTML-теги
    return BeautifulSoup(text, "html.parser").get_text()

def download_image(image_name):
    image_url = f"https://en.wikipedia.org/wiki/Special:FilePath/{image_name}"
    response = requests.get(image_url)
    if response.status_code == 200:
        image_path = os.path.join(base_dir, image_name)
        with open(image_path, 'wb') as f:
            f.write(response.content)
        return image_path
    return None

def main(base_dir, number_of_dirs, files_per_dir):
    if not os.path.exists(base_dir):
        os.makedirs(base_dir)

    report_path = os.path.join(base_dir, "report.txt")
    with open(report_path, 'w', encoding='utf-8') as report_file:
        for i in range(number_of_dirs):
            dir_name = f"Тема_{i + 1}"
            dir_path = os.path.join(base_dir, dir_name)
            os.makedirs(dir_path)
            report_file.write(f"Создана директория: {dir_path}\n")

            for j in range(files_per_dir):
                file_type = random.choice(['txt', 'docx', 'jpg'])
                if file_type == 'txt':
                    article_text = get_random_article()
                    file_name = f"Документ_Тема_{i + 1}_Файл_{j + 1}.txt"
                    file_path = os.path.join(dir_path, file_name)
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(article_text)
                    report_file.write(f"Создан файл: {file_path}\n")
                elif file_type == 'docx':
                    article_text = get_random_article()
                    file_name = f"Документ_Тема_{i + 1}_Файл_{j + 1}.docx"
                    doc = Document()
                    doc.add_paragraph(article_text)
                    doc.save(os.path.join(dir_path, file_name))
                    report_file.write(f"Создан файл: {file_path}\n")
                elif file_type == 'jpg':
                    # Здесь просто указываем пример имени изображения
                    image_name = "SampleImage.jpg"  # Укажите реальное имя изображения
                    image_path = download_image(image_name)
                    if image_path:
                        report_file.write(f"Создан файл: {image_path}\n")
                    else:
                        # Если изображение не найдено, создаем заглушку
                        file_name = f"Документ_Тема_{i + 1}_Файл_{j + 1}.jpg"
                        empty_image_path = os.path.join(dir_path, file_name)
                        with open(empty_image_path, 'wb') as f:
                            f.write(b'\x00' * 100)  # Пустой файл
                        report_file.write(f"Создан пустой файл: {empty_image_path}\n")

if __name__ == "__main__":
    base_dir = "C:\\RandomFiles"  # Путь к основной директории
    number_of_dirs = 5  # Количество создаваемых директорий
    files_per_dir = 3  # Количество файлов в каждой директории
    main(base_dir, number_of_dirs, files_per_dir)
