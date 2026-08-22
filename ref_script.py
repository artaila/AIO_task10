#!/usr/bin/env python3
from pysam import Fastafile

import argparse
import datetime
import os
import pandas as pd
import logging
import sys


def main():
    parser = argparse.ArgumentParser(description='Скрипт для выявления, какой из двух аллелей является референсным, а какой – альтернативным.')
    parser.add_argument('--filename', '-f', default='FP_SNPs_10k_GB38_twoAllelsFormat.tsv', help='путь к файлу для обработки')
    parser.add_argument('--output', '-o', default='FP_SNPs_10k_GB38_twoAllelsFormat_restored.tsv', help='путь для сохранения результата')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--reference-chromes', '-c', default='/ref/GRCh38.d1.vd1_mainChr/sepChrs/', help='путь к папке с FASTA-файлами хромосом')
    group.add_argument('--reference', '-r', help='путь к FASTA-референсу')
    parser.add_argument('--verbose', '-v', action='store_true', help='выводить дополнительную информацию')
    parser.add_argument('--debug', '-d', action='store_true', help='выводить максимум информации')
    
    parser.add_argument('--log-file', '-l', default='logs.txt', help='путь к файлу для сохранения логов')
    
    args = parser.parse_args()
    
    if args.debug:
        log_level = logging.DEBUG
    elif args.verbose:
        log_level = logging.INFO
    else:
        log_level = logging.ERROR
    log_handlers = [logging.StreamHandler(sys.stdout)]

    if args.log_file:
        log_handlers.append(logging.FileHandler(args.log_file, mode='a', encoding='utf-8'))

    logging.basicConfig(
        level=log_level,
        format='%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=log_handlers
    )
    
    logging.info('Открытие файлов')
    
    if not os.path.exists(args.filename):
        logging.error(f'Входной файл не найден: {args.filename}')
        sys.exit(1)
    if args.reference:
        if not os.path.exists(args.reference):
            logging.error(f'Референс не найден: {args.reference}')
            sys.exit(1)
    else:
        if args.reference_chromes and not os.path.exists(args.reference_chromes):
            logging.error(f'Папка с референсом не найдена: {args.reference_chromes}')
            sys.exit(1)

    try:
        df = pd.read_csv(args.filename, sep='\t')
    except Exception as e:
        logging.error(f'Ошибка чтения: {args.filename}')
        logging.debug(f'{e}')
        sys.exit(1)

    expected_header = ['#CHROM', 'POS', 'ID', 'allele1', 'allele2']

    if list(df.columns) != expected_header:
        logging.error(f'{args.filename} не обладает правильным форматом заголовка')
        logging.error(f'Ожидалось: {expected_header}')
        logging.error(f'Получено: {list(df.columns)}')
        sys.exit(1)

    logging.info(f'Строк в файле: {len(df)}')
    logging.info(f'Обработка файла')
    fasta_cache = {}
    chroms = set()
    refs = []
    alts = []
    warnings_count = 0

    single_fasta = None
    if args.reference:
        single_fasta = Fastafile(args.reference)

    for index, row in df.iterrows():
        chrom = str(row['#CHROM'])
        pos = int(row['POS'])
        r_id = str(row['ID'])
        a1 = str(row['allele1'])
        a2 = str(row['allele2'])

        if single_fasta:
            fasta = single_fasta
            if chrom not in chroms:
                logging.info(f'Обработка хромосомы {chrom}')
                chroms.add(chrom)
        else:
            if chrom not in chroms:
                logging.info(f'Обработка хромосомы {chrom}')
                chrom_path = os.path.join(args.reference_chromes, f'{chrom}.fa')
                if not os.path.exists(chrom_path):
                    logging.error(f'Входной файл не найден: {chrom_path}')
                    sys.exit(1)
                chroms.add(chrom)
                fasta_cache[chrom] = Fastafile(chrom_path)
            fasta = fasta_cache[chrom]

        try:
            true_ref = fasta.fetch(chrom, pos - 1, pos).upper()
        except Exception as e:
            logging.error(f'Позиции {pos} нет в хромосоме {chrom}')
            logging.debug(f'{e}')
            sys.exit(1)

        if a1 == true_ref:
            refs.append(a1)
            alts.append(a2)
        elif a2 == true_ref:
            refs.append(a2)
            alts.append(a1)
        else:
            logging.warning(f'Оба аллеля альтернативны {chrom}:{pos}')
            refs.append(true_ref)
            alts.append(f'{a1},{a2}')

    df['REF'] = refs
    df['ALT'] = alts
    df = df[['#CHROM', 'POS', 'ID', 'REF', 'ALT']]

    if single_fasta:
        single_fasta.close()
    else:
        for f in fasta_cache.values():
            f.close()

    try:
        df.to_csv(args.output, sep='\t', index=False)
    except Exception as e:
        logging.error(f'Ошибка при записи файлов')
        logging.error(f'{e}')
        sys.exit(1)
    logging.info(f'Файл успешно сохранен в {args.output}')

if __name__ == '__main__':
    main()
