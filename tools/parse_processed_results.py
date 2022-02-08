import csv
import os

with open('../results/processed.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=['algorithm', 'mu', 'exponential', 'base', 'lb', 'ub'])
    writer.writeheader()

    for dirname in os.listdir('../results/processed'):
        directory = '../results/processed/' + dirname + '/'
        algorithm, mu = dirname.split('-')

        # Which of the two models (i.e., exponential and polynomial) is the better fit?
        with open(directory + 'table_Fitted-models.tex') as f:
            txt = f.read()
        exponential = (txt.split('tabularnewline')[2].find('mathbf') != -1)

        # Find the best base of the exponential (i.e., a point estimate)
        with open(directory + 'table_Fitted-models.csv') as f:
            reader = csv.DictReader(f)
            row = next(reader)
        base = row['Support Loss'][:-1]

        # Find the confidence interval for the base
        with open(directory + 'table_Bootstrap-intervals-of-parameters.csv') as f:
            reader = csv.DictReader(f)
            row = next(reader)
        lb = row[None][0][1:]
        ub = row[None][1][:-1]

        writer.writerow({'algorithm': algorithm, 'mu': mu,
                         'exponential': exponential, 'base': base, 'lb': lb, 'ub': ub})
