# AIO_task10

Репозиторий содержит в себе Dockerfile базовыми инструментами для работы с данными NGS и python-скрипт 'ref\_script.py', а также тестовый файл с однонуклеотидными заменами 'FP\_SNPs.txt', предобработанный файл 'FP\_SNPs\_10k\_GB38\_twoAllelsFormat.tsv', итоговый файл 'FP\_SNPs\_10k\_GB38\_twoAllelsFormat\_restored.tsv' и лог-файл работы скрипта LOGS.txt.

Установка и сборка:
```bash
    git clone https://github.com/artaila/AIO_task10.git
    cd AIO_task10
    docker build -t bio-tools .
```

Команда для запуска:
```bash
    docker run -it --rm \
      -v /mnt/data/ref/GRCh38.d1.vd1_mainChr/sepChrs/:/ref/GRCh38.d1.vd1_mainChr/sepChrs/ \
      bio-tools
```
  
---

Программы установлены изолированно в директорию `/soft`. Доступны следующие инструменты:

| Программа | Версия | Путь установки |
| :--- | :---  | :--- |
| **libdeflate** | 1.25 | `/soft/libdeflate-1.25` |
| **htslib** | 1.24 | `/soft/htslib-1.24` |
| **samtools** | 1.24 | `/soft/samtools-1.24` |
| **bcftools** | 1.24 | `/soft/bcftools-1.24` |
| **vcftools** | 0.1.17 | `/soft/vcftools-0.1.17` |

Также устанавливается пакет **pysam** версии 0.23.3. и pandas версии 3.0.5

Разбиение исходного референса предполагалось при помощи команды:

```bash
    for chr in {1..22} X Y M; do
        samtools faidx GRCh38.d1.vd1.fa "chr${chr}" > "chr${chr}.fa"
        samtools faidx "chr${chr}.fa"
    done
```
Прилагаемый скрипт может обработать папку с разделенными хромосомами /ref/GRCh38.d1.vd1_mainChr/sepChrs/ , а может обработать и неразделенный референс GRCh38.d1.vd1.fa, если передать его как аргумент --reference / -r.

usage: ref_script.py [-h] [--filename FILENAME] [--output OUTPUT] [--reference-chromes REFERENCE_CHROMES | --reference REFERENCE] [--verbose]
                     [--debug]

Скрипт для выявления, какой из двух аллелей является референсным, а какой – альтернативным.

optional arguments:
  -h, --help            show this help message and exit
  --filename FILENAME, -f FILENAME
                        путь к файлу для обработки
  --output OUTPUT, -o OUTPUT
                        путь для сохранения результата
  --reference-chromes REFERENCE_CHROMES, -c REFERENCE_CHROMES
                        путь к папке с FASTA-файлами хромосом
  --reference REFERENCE, -r REFERENCE
                        путь к FASTA-референсу
  --verbose, -v         выводить дополнительную информацию
  --debug, -d           выводить максимум информации

---

В качестве исходных данных использовался файл FP_SNPs.txt из пакета GRAF v2.4
В ходе предобработки убрана 1000 вариантов X хромосомы. Итоговый файл FP_SNPs_10k_GB38_twoAllelsFormat_restored.tsv представляет собой табулированный текстовый файл, количество строк  осталось неизменным.
Для 9991 варианта успешно выявылен референсный аллель. Для 9 позиций скрипт выдал предупреждение, в этих локусах ни один из предоставленных аллелей не совпал с референсным геномом. Для сохранения данных в колонку REF был принудительно записан истинный нуклеотид из референса, а в колонку ALT оба исходных аллеля через запятую.
