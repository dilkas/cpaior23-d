import os

def genCsvRow( data ):
    return ','.join([str(x) for x in data])

def genCSV( dirName, fileName, headers, items, data):
    with open(dirName+"/"+fileName, "w") as file:
        file.write(","+genCsvRow(headers) + '\n')
        for i in range(0, len(data)):
            file.write(str(items[i])+","+genCsvRow(data[i]) + '\n')
