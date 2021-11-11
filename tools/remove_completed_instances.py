import csv
import glob
import os

with open('results.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        for filename in glob.glob('data/' + row['instance'] + '.*'):
            print(filename)
            os.remove(filename)
