import csv
import glob


def get_instance_name(filename):
    return filename[filename.rindex("/") + 1 : filename.rindex(".")]


def extract_tw(filename, index):
    with open(filename) as f:
        words = f.read().split()
        try:
            return int(words[index])
        except IndexError:
            pass


data = []

for tw_file in glob.glob("results/exact_tw/*.exacttw"):
    exact = extract_tw(tw_file, 3)
    if exact is not None:
        item = {}
        item["instance"] = get_instance_name(tw_file)
        item["exact"] = exact
        item["approximate"] = extract_tw(tw_file[: tw_file.rindex(".")] + ".tw", -1)
        data.append(item)

with open("results/tw_comparison.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=["instance", "exact", "approximate"])
    writer.writeheader()
    for d in data:
        writer.writerow(d)
