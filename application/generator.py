#!/usr/bin/env python

import time
import os

import mysql.connector
from mysql.connector import Error
from faker import Faker

db_host = os.environ.get('DB_HOST', 'localhost')
db_name = os.environ.get('DB_NAME', 'hsa_l18')
db_user = os.environ.get('DB_USER_NAME', 'root')
db_pass = os.environ.get('DB_USER_PASSWORD', 'pAsSw1oR2D3')

SEED_NUM=1000
Faker.seed(SEED_NUM)
fake = Faker()

create_table_sql = """
CREATE TABLE `note` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Note ID',
    `title` varchar(40) NOT NULL COMMENT 'Note Title',
    `description` text NOT NULL COMMENT 'Note Description',
    `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Note Created Time',
    `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Note Modified Time',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""

try:
    conn = mysql.connector.connect(host=db_host, database = db_name,
                                       user=db_user, password=db_pass)
    if conn.is_connected():
        cursor = conn.cursor()

        try:
            cursor.execute(create_table_sql)
            print("Table `note` created.")
        except Exception as e:
            print("Table `note` already exists. Skipping...", e)

        row = {}
        n = 0

        print("Inserting %s rows..." % SEED_NUM)
        while True:
            if n == SEED_NUM:
               break

            n += 1
            row = [fake.text(max_nb_chars=20), fake.paragraph(nb_sentences=2)]

            cursor.execute('INSERT INTO `note` (title, description) VALUES ("%s", "%s");' \
                % (row[0], row[1])
            )

            if n % 100 == 0:
                time.sleep(0.1)
                conn.commit()

        print("Done!")
except Error as e :
    print ("error", e)
    pass
except Exception as e:
    print ("Unknown error %s", e)
finally:
    #closing database connection.
    if(conn and conn.is_connected()):
        conn.commit()
        cursor.close()
        conn.close()