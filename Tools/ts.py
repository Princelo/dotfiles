from time import strftime, localtime
import sys
import time
import datetime

if len(sys.argv) == 1:
    ut = time.time()
    print(int(ut))
    ut *= 1000
    print(int(ut))
    exit(0)

if (len(sys.argv) == 2):
    if len(sys.argv[1]) not in [10, 13]:
        exit(0)
    ts = int(sys.argv[1])
    if len(sys.argv[1]) == 13:
        ts /= 1000
    print(strftime('%Y-%m-%d %H:%M:%S', localtime(ts)))
else:
    year, month, date = sys.argv[1].split("-")
    hour, minute, second = sys.argv[2].split(":")
    print(int(datetime.datetime(int(year), int(month), int(date), int(hour),
                                int(minute), int(second)).timestamp()))
    print(int(datetime.datetime(int(year), int(month), int(date), int(hour),
                                int(minute), int(second)).timestamp()) * 1000)
